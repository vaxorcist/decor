# decor/app/controllers/owners_controller.rb - version 1.2
# Fixed password change validation (lines 57-76)
# Now requires BOTH current_password AND password when attempting password change
# This prevents illogical scenarios like providing current_password without new password

class OwnersController < ApplicationController
  before_action :set_owner, only: %i[show edit update]
  before_action -> { require_owner(@owner) }, only: %i[edit update]
  before_action :load_invite, only: %i[new create]

  def index
    owners = Owner.order(:user_name).search(params[:query])

    if params[:country].present?
      visibility_values = Current.owner.present? ? %w[public members_only] : %w[public]
      owners = owners.where(country: params[:country], country_visibility: visibility_values)
    end

    paginate owners
  end

  def new
    if @invite.nil? || @invite.expired? || @invite.accepted?
      redirect_to root_path, alert: "Invalid or expired invitation."
      return
    end

    @owner = Owner.new(email: @invite.email)
  end

  def create
    if @invite.nil? || @invite.expired? || @invite.accepted?
      redirect_to root_path, alert: "Invalid or expired invitation."
      return
    end

    @owner = Owner.new(create_owner_params)

    if @owner.save
      @invite.accept!
      session[:owner_id] = @owner.id
      redirect_to @owner, notice: "Welcome! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @computers = @owner.computers.includes(:computer_model)
    @components = @owner.components.includes(:component_type, :computer)
  end

  def edit
  end

  def update
    # Check if user is attempting to change password
    # Password change requires current password verification for security
    if password_change_attempted?
      # Both current_password and new password must be provided when changing password
      if owner_params[:current_password].blank?
        @owner.errors.add(:current_password, "is required when changing password")
        render :edit, status: :unprocessable_entity
        return
      end

      if owner_params[:password].blank?
        @owner.errors.add(:password, "can't be blank when changing password")
        render :edit, status: :unprocessable_entity
        return
      end

      # Verify current password is correct using BCrypt authentication
      unless @owner.authenticate(owner_params[:current_password])
        @owner.errors.add(:current_password, "is incorrect")
        render :edit, status: :unprocessable_entity
        return
      end
    end

    # Remove current_password from params before update
    # current_password is not a database field - only used for verification
    update_params = owner_params.except(:current_password)

    if @owner.update(update_params)
      redirect_to @owner, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_owner
    @owner = Owner.find(params[:id])
  end

  def load_invite
    @invite = Invite.find_by(token: params[:token]) if params[:token].present?
  end

  # Check if user is trying to change password
  # Password change is attempted if either current_password or password fields are present
  # This allows profile updates without requiring password change
  def password_change_attempted?
    owner_params[:current_password].present? || owner_params[:password].present?
  end

  # Permitted parameters for updating existing owner
  # Includes password fields for optional password change
  def owner_params
    params.require(:owner).permit(
      :user_name, :real_name, :email, :country, :website,
      :real_name_visibility, :email_visibility, :country_visibility,
      :current_password, :password, :password_confirmation
    )
  end

  # Permitted parameters for creating new owner via invitation
  # Does not include current_password (not needed for new accounts)
  def create_owner_params
    params.require(:owner).permit(
      :user_name, :real_name, :email, :country, :website, :password, :password_confirmation,
      :real_name_visibility, :email_visibility, :country_visibility
    )
  end
end
