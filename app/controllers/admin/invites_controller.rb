# decor/app/controllers/admin/invites_controller.rb - version 1.1
# Changes from v1.0:
# - deliver_later → deliver_now for invite_email
#   Rationale: this is a single admin-triggered email, not a bulk operation.
#   deliver_later required a running Solid Queue worker to process, which meant
#   letter_opener never fired in development and failures were silent in production.
#   deliver_now is synchronous, works with letter_opener, and gives the admin
#   immediate feedback if delivery fails (raise_delivery_errors = true in production).

module Admin
  class InvitesController < BaseController
    def index
      @invites = Invite.pending.order(sent_at: :desc)
    end

    def new
      @invite = Invite.new
    end

    def create
      @invite = Invite.new(invite_params)

      if @invite.save
        InviteMailer.invite_email(@invite).deliver_now
        redirect_to admin_invites_path, notice: "Invitation sent to #{@invite.email}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @invite = Invite.find(params[:id])
      @invite.destroy
      redirect_to admin_invites_path, notice: "Invitation was deleted."
    end

    private

    def invite_params
      params.require(:invite).permit(:email)
    end
  end
end
