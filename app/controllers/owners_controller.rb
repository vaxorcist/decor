# decor/app/controllers/owners_controller.rb
# version 2.1
# v2.1 (Session 56): Newsletter feature.
#   - Added :newsletter to owner_params and create_owner_params so the checkbox
#     on owners/edit and owners/new submits the newsletter preference correctly.
#   - newsletter is an integer column (0/1); Rails check_box helpers submit the
#     unchecked_value (0) via a hidden field, so no extra handling is needed.
# v2.0 (Session 45): Software feature Session C.
# (all prior version notes preserved in the codebase — omitted here for brevity)

class OwnersController < ApplicationController
  before_action :set_owner, only: %i[show edit update destroy computers peripherals components connections software]
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

  # Summary page — shows profile info and section counts only.
  def show
    @computer_count         = @owner.computers.where(device_type: :computer).count
    @peripheral_count       = @owner.computers.where(device_type: :peripheral).count
    @component_count        = @owner.components.count
    @connection_group_count = @owner.connection_groups.count
    @software_count         = @owner.software_items.count
  end

  def computers
    @computers = @owner.computers
                       .where(device_type: :computer)
                       .eager_load(:computer_model)
                       .order(Arel.sql("computer_models.name ASC"))
  end

  def peripherals
    @peripherals = @owner.computers
                         .where(device_type: :peripheral)
                         .eager_load(:computer_model)
                         .order(Arel.sql("computer_models.name ASC"))
  end

  def components
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

  def connections
    @connection_groups = @owner.connection_groups
                               .includes(:connection_type,
                                         connection_members: { computer: :computer_model })
                               .order(:owner_group_id)
  end

  def software
    @software_items = @owner.software_items
                            .eager_load(:software_name, :software_condition,
                                        computer: :computer_model)
                            .order(
                              Arel.sql(
                                "software_names.name ASC, " \
                                "software_items.version ASC NULLS LAST"
                              )
                            )
  end

  def edit
  end

  def update
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

    update_params = owner_params.except(:current_password)

    if @owner.update(update_params)
      redirect_to @owner, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

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
      :current_password, :password, :password_confirmation,
      :newsletter  # added Session 56 — newsletter preference (0/1)
    )
  end

  def create_owner_params
    params.require(:owner).permit(
      :user_name, :real_name, :email, :country, :website, :password, :password_confirmation,
      :real_name_visibility, :email_visibility, :country_visibility,
      :newsletter  # added Session 56 — newsletter preference (0/1)
    )
  end
end
