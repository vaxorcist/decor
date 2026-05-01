# decor/app/controllers/admin/newsletters_controller.rb
# version 1.0
# Session 56: Newsletter feature — initial implementation.
#
# Manages newsletters: upload from an MD file, preview, send to subscribers.
#
# Actions:
#   index          — list all stored newsletters (subject, created_at, row actions)
#   new            — form to upload a .md file + enter subject
#   create         — reads the uploaded file, saves Newsletter (before_save renders HTML)
#   show           — preview the rendered HTML body; links to Send
#   destroy        — delete a newsletter record
#   send_newsletter (GET)  — form: choose "all subscribed" or "specific owner"
#   send_newsletter (POST) — send via NewsletterMailer#deliver_now
#
# before_action scoping:
#   set_newsletter is scoped to only: actions that need @newsletter.
#   index and new do NOT need it — following the project rule (learned Session 46).

module Admin
  class NewslettersController < BaseController
    before_action :set_newsletter, only: %i[show destroy send_newsletter]

    # GET /admin/newsletters
    # Lists all newsletters ordered newest first.
    def index
      @newsletters = Newsletter.order(created_at: :desc)
    end

    # GET /admin/newsletters/new
    # Renders the upload form (subject field + file picker).
    def new
      @newsletter = Newsletter.new
    end

    # POST /admin/newsletters
    # Reads the uploaded .md file, builds a Newsletter, saves it.
    # Newsletter#before_save generates html_body from markdown_body via Redcarpet.
    def create
      uploaded_file = params.dig(:newsletter, :md_file)

      if uploaded_file.blank?
        @newsletter = Newsletter.new(subject: params.dig(:newsletter, :subject))
        @newsletter.errors.add(:md_file, "must be provided")
        render :new, status: :unprocessable_entity
        return
      end

      # Read raw markdown from the uploaded file.
      markdown_body = uploaded_file.read.force_encoding("UTF-8")

      @newsletter = Newsletter.new(
        subject:       params.dig(:newsletter, :subject).to_s.strip,
        markdown_body: markdown_body
        # html_body is NOT set here — Newsletter#before_save generates it.
      )

      if @newsletter.save
        redirect_to admin_newsletter_path(@newsletter),
                    notice: "Newsletter \"#{@newsletter.subject}\" uploaded successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/newsletters/:id
    # Shows a preview of the rendered HTML body.
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
      if request.post?
        case params[:recipient]
        when "all"
          # Send to every owner with newsletter = 1 (subscribed).
          owners = Owner.newsletter_subscribed
          count  = owners.count

          if count.zero?
            redirect_to admin_newsletter_path(@newsletter),
                        alert: "No subscribed owners found — newsletter was not sent."
            return
          end

          # Enqueue one job per recipient so a single failure does not block others.
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
          # No recipient radio selected.
          flash.now[:alert] = "Please select a recipient."
          render :send_newsletter, status: :unprocessable_entity
        end
      end
      # GET: render send_newsletter.html.erb (recipient selection form).
      # @owners is preloaded for the "specific owner" Tom Select dropdown.
      @owners = Owner.order(:user_name)
    end

    private

    def set_newsletter
      @newsletter = Newsletter.find(params[:id])
    end
  end
end
