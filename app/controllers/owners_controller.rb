# decor/app/controllers/owners_controller.rb - version 1.4
# show action: computers ordered by model name; components ordered by computer model name,
# computer serial number, component type name.
# eager_load used (instead of includes + left_joins) so that joined table columns are
# available in ORDER BY in a single query. NULLS LAST puts spare components after
# computer-attached ones.

class OwnersController < ApplicationController
  before_action :set_owner, only: %i[show edit update destroy]
  before_action -> { require_owner(@owner) }, only: %i[edit update destroy]
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
    # Computers: ordered by model name (eager_load forces LEFT OUTER JOIN, enabling ORDER BY
    # on the joined table; inner join is fine here since computer_model is always present)
    @computers = @owner.computers
                       .eager_load(:computer_model)
                       .order(Arel.sql("computer_models.name ASC"))

    # Components: ordered by computer model name, then computer serial number, then component
    # type name. eager_load generates LEFT OUTER JOINs for all associations in one query,
    # which is required to ORDER BY columns on optionally-present associations (computer,
    # computer_model). NULLS LAST ensures spare components (no computer) sort after
    # computer-attached ones.
    # Arel.sql() is required for multi-table ORDER BY strings — Rails rejects raw strings
    # that contain non-attribute references (dots, NULLS LAST) as a safety guard.
    @components = @owner.components
                        .eager_load(:component_type, computer: :computer_model)
                        .order(
                          Arel.sql(
                            "computer_models.name ASC NULLS LAST, " \
                            "computers.serial_number ASC NULLS LAST, " \
                            "component_types.name ASC"
                          )
                        )
  end

  def edit
  end

  def update
    # Check if user is attempting to change password
    # Password change requires current password verification for security
    if password_change_attempted?
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

  # Account self-deletion
  # User can only delete their own account (enforced by require_owner before_action)
  # Requires password confirmation for security
  # Automatically destroys all associated computers and components (dependent: :destroy)
  # Logs out user and redirects to home page
  def destroy
    unless params[:password].present? && @owner.authenticate(params[:password])
      redirect_to edit_owner_path(@owner), alert: "Incorrect password. Account was not deleted."
      return
    end

    user_name = @owner.user_name
    @owner.destroy
    log_out

    redirect_to root_path, notice: "Account '#{user_name}' and all associated data have been permanently deleted."
  end

  private

  def set_owner
    @owner = Owner.find(params[:id])
  end

  def load_invite
    @invite = Invite.find_by(token: params[:token]) if params[:token].present?
  end

  def password_change_attempted?
    owner_params[:current_password].present? || owner_params[:password].present?
  end

  def owner_params
    params.require(:owner).permit(
      :user_name, :real_name, :email, :country, :website,
      :real_name_visibility, :email_visibility, :country_visibility,
      :current_password, :password, :password_confirmation
    )
  end

  def create_owner_params
    params.require(:owner).permit(
      :user_name, :real_name, :email, :country, :website, :password, :password_confirmation,
      :real_name_visibility, :email_visibility, :country_visibility
    )
  end
end
