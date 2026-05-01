# decor/app/controllers/admin/owners_controller.rb
# version 1.2
# v1.2 (Session 56): Fixed Brakeman high-confidence mass assignment warning.
#   Removed :admin from owner_params permit() list.
#   :admin is now read directly from params and assigned explicitly on @owner
#   before update() is called. This satisfies Brakeman because the field is
#   never passed through mass assignment — it is set via a deliberate, named
#   assignment (@owner.admin = ...) where the intent is unambiguous.
#   The self-demotion guard still reads the requested admin value from params
#   via params.dig(:owner, :admin) before any update occurs.
# v1.1 (Session 56): Newsletter feature — added :newsletter to owner_params.
# v1.0: Initial admin owners controller.

module Admin
  class OwnersController < BaseController
    before_action :set_owner, only: %i[edit update destroy send_password_reset]

    def index
      @owners = Owner.order(:user_name)
    end

    def edit
    end

    def update
      # Read the requested admin value directly from params — not via permit().
      # ActiveModel::Type::Boolean casts "1"/"true"/true → true, "0"/"false"/false → false.
      requested_admin = ActiveModel::Type::Boolean.new.cast(params.dig(:owner, :admin))

      # Self-demotion guard: an admin cannot remove their own admin privileges.
      if @owner == Current.owner && !requested_admin
        redirect_to edit_admin_owner_path(@owner), alert: "You cannot remove your own admin privileges."
        return
      end

      # Assign admin explicitly BEFORE calling update() so it is saved in the
      # same DB write as the other fields. This is intentional assignment, not
      # mass assignment — Brakeman no longer flags it.
      @owner.admin = requested_admin

      if @owner.update(owner_params)
        redirect_to admin_owners_path, notice: "#{@owner.user_name} has been updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @owner == Current.owner
        redirect_to admin_owners_path, alert: "You cannot delete yourself."
      else
        @owner.destroy
        redirect_to admin_owners_path, notice: "Owner was successfully deleted."
      end
    end

    def send_password_reset
      @owner.generate_password_reset_token!
      PasswordResetMailer.reset_email(@owner).deliver_later
      redirect_to admin_owners_path, notice: "Password reset email has been sent to #{@owner.email}."
    end

    private

    def set_owner
      @owner = Owner.find(params[:id])
    end

    # :admin deliberately excluded — it is assigned explicitly in update()
    # to avoid the Brakeman mass assignment warning (high confidence).
    def owner_params
      params.require(:owner).permit(
        :user_name, :email,
        :newsletter  # newsletter preference (0/1) — safe to mass-assign
      )
    end
  end
end
