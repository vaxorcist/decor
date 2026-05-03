# decor/app/controllers/admin/newsletters_controller.rb
# version 1.1
# v1.1 (Session 58): Fixed @owners nil on POST failure in send_newsletter.
#
#   Root cause: `render` in a Rails controller action renders the view
#   synchronously and immediately — instance variables assigned AFTER the
#   `render` call are not visible to the already-rendered template.
#   The original code placed `@owners = Owner.order(:user_name)` at the bottom
#   of the action, after the `if request.post?` block. Two POST failure paths
#   fired `render :send_newsletter` before that line was reached:
#     1. `when "specific"` + blank owner_id — calls `render` then `return`,
#        so `@owners` was never assigned at all.
#     2. `else` (no recipient selected) — calls `render` (view rendered with
#        nil @owners), then falls through to the assignment (too late).
#   The view's `@owners.each` on line 75 raised `undefined method 'each' for nil`.
#
#   Fix: move `@owners = Owner.order(:user_name)` to the very top of the action.
#   It runs on every code path — GET form render, POST success (harmless
#   extra query before the redirect), and all POST failure re-renders.
#   The query is a single indexed scan on user_name; the cost is negligible.
#
# v1.0 (Session 56): Initial implementation.

module Admin
  class NewslettersController < BaseController
    before_action :set_newsletter, only: %i[show destroy send_newsletter]

    # GET /admin/newsletters
    def index
      @newsletters = Newsletter.order(created_at: :desc)
    end

    # GET /admin/newsletters/new
    def new
      @newsletter = Newsletter.new
    end

    # POST /admin/newsletters
    def create
      uploaded_file = params.dig(:newsletter, :md_file)

      if uploaded_file.blank?
        @newsletter = Newsletter.new(subject: params.dig(:newsletter, :subject))
        @newsletter.errors.add(:md_file, "must be provided")
        render :new, status: :unprocessable_entity
        return
      end

      markdown_body = uploaded_file.read.force_encoding("UTF-8")

      @newsletter = Newsletter.new(
        subject:       params.dig(:newsletter, :subject).to_s.strip,
        markdown_body: markdown_body
      )

      if @newsletter.save
        redirect_to admin_newsletter_path(@newsletter),
                    notice: "Newsletter \"#{@newsletter.subject}\" uploaded successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/newsletters/:id
    def show
    end

    # DELETE /admin/newsletters/:id
    def destroy
      subject = @newsletter.subject
      @newsletter.destroy
      redirect_to admin_newsletters_path,
                  notice: "Newsletter \"#{subject}\" has been deleted."
    end

    # GET  /admin/newsletters/:id/send_newsletter — recipient selection form
    # POST /admin/newsletters/:id/send_newsletter — deliver immediately via deliver_now
    def send_newsletter
      # Preload @owners unconditionally so the Tom Select dropdown is always
      # available — on the initial GET, on POST success (harmless before redirect),
      # and critically on POST validation failures that re-render this form.
      # Previously placed at the bottom of the action, which caused
      # `undefined method 'each' for nil` when render fired before that line.
      @owners = Owner.order(:user_name)

      if request.post?
        case params[:recipient]
        when "all"
          owners = Owner.newsletter_subscribed
          count  = owners.count

          if count.zero?
            redirect_to admin_newsletter_path(@newsletter),
                        alert: "No subscribed owners found — newsletter was not sent."
            return
          end

          owners.each do |owner|
            NewsletterMailer.send_newsletter(owner, @newsletter).deliver_now
          end

          redirect_to admin_newsletters_path,
                      notice: "Newsletter \"#{@newsletter.subject}\" sent to #{count} subscriber(s)."

        when "specific"
          if params[:owner_id].blank?
            flash.now[:alert] = "Please select an owner."
            render :send_newsletter, status: :unprocessable_entity
            return
          end

          owner = Owner.find(params[:owner_id])
          NewsletterMailer.send_newsletter(owner, @newsletter).deliver_now

          redirect_to admin_newsletters_path,
                      notice: "Newsletter \"#{@newsletter.subject}\" sent to #{owner.user_name}."

        else
          flash.now[:alert] = "Please select a recipient."
          render :send_newsletter, status: :unprocessable_entity
        end
      end
    end

    private

    def set_newsletter
      @newsletter = Newsletter.find(params[:id])
    end
  end
end
