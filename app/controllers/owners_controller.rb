# decor/app/controllers/owners_controller.rb
# version 2.0
# v2.0 (Session 45): Software feature Session C.
#   Added :software to the before_action :set_owner list.
#   Added @software_count to show action (drives the summary card count).
#   Added software action — loads @software_items with eager_load for
#   ORDER BY on software_names.name. No auth guard (public, consistent with
#   all other read-only sub-pages in this controller).
# v1.9 (Session 41): Appliances → Peripherals merger Phase 2.
#   Removed :appliances from before_action :set_owner list.
#   Removed @appliance_count from show action (no longer a separate device type).
#   Removed appliances action entirely — peripheral action already covers
#   device_type_peripheral? records, which now includes former appliances.
# v1.8 (Session 38): Connections sub-page added.
# v1.7 (Session 25): Added peripherals action and @peripheral_count.
# v1.6 (Session 23): Split owner show page into three sub-pages.
# v1.5 (Session 18): show action: split @computers into computer/appliance.
# v1.4: computers and components ordered; eager_load for ORDER BY on joined tables.

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
  # Full tables live in the computers / peripherals / components / connections /
  # software sub-pages.
  # @peripheral_count covers all device_type_peripheral? records (formerly also
  # appliances, merged in Session 41).
  # @software_count added Session 45.
  def show
    @computer_count         = @owner.computers.where(device_type: :computer).count
    @peripheral_count       = @owner.computers.where(device_type: :peripheral).count
    @component_count        = @owner.components.count
    @connection_group_count = @owner.connection_groups.count
    @software_count         = @owner.software_items.count
  end

  # Sub-page: owner's computers (device_type: computer).
  # Ordered by model name; eager_load required for ORDER BY on joined table.
  def computers
    @computers = @owner.computers
                       .where(device_type: :computer)
                       .eager_load(:computer_model)
                       .order(Arel.sql("computer_models.name ASC"))
  end

  # Sub-page: owner's peripherals (device_type: peripheral).
  # Covers all peripheral records — former appliances were merged into this
  # device type in Session 41. Same ordering pattern as computers.
  def peripherals
    @peripherals = @owner.computers
                         .where(device_type: :peripheral)
                         .eager_load(:computer_model)
                         .order(Arel.sql("computer_models.name ASC"))
  end

  # Sub-page: owner's components.
  # Ordered by computer model name, then serial number, then component type.
  # NULLS LAST keeps spare components (no computer) at the bottom.
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

  # Sub-page: owner's connections (connection groups).
  # Ordered by owner_group_id so the owner's own numbering scheme is respected.
  # Eager-load strategy (avoids N+1 on the multi-row connections table):
  #   :connection_type                       — type name column
  #   connection_members: { computer: :computer_model }  — port rows
  # The view sorts members in memory via .sort_by(&:owner_member_id); the
  # preloaded collection is used, so no extra DB queries fire per row.
  def connections
    @connection_groups = @owner.connection_groups
                               .includes(:connection_type,
                                         connection_members: { computer: :computer_model })
                               .order(:owner_group_id)
  end

  # Sub-page: owner's software items.
  # Ordered by software name (joined table — needs eager_load), then version
  # NULLS LAST so items without a version sort after versioned ones.
  # No auth guard — publicly accessible, consistent with all other read-only
  # sub-pages in this controller.
  # Added Session 45 (Software feature Session C).
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
    # Check if user is attempting to change password.
    # Password change requires current password verification for security.
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

    # Remove current_password from params before update.
    # current_password is not a database field — only used for verification.
    update_params = owner_params.except(:current_password)

    if @owner.update(update_params)
      redirect_to @owner, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Account self-deletion.
  # User can only delete their own account (enforced by require_owner before_action).
  # Requires password confirmation for security.
  # Automatically destroys all associated computers and components (dependent: :destroy).
  # Logs out user and redirects to home page.
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
