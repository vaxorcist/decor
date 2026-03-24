# decor/app/controllers/connection_groups_controller.rb
# version 1.1
# v1.1 (Session 38): Connections UI overhaul.
#   - index: now redirects to connections_owner_path(@owner) — the new owner
#     sub-page at /owners/:id/connections replaces the old standalone index.
#   - create/update/destroy: redirect targets changed from owner_connection_groups_path
#     to connections_owner_path so the user lands on the new connections tab.
#   - new: pre-sets owner_group_id to the next available value for this owner;
#     pre-builds 2 member rows with sequential owner_member_ids (1, 2).
#   - edit: pre-builds 1 blank member row with the next available owner_member_id,
#     replacing the previous blank build without an explicit ID.
#   - connection_group_params: added :owner_group_id; nested member attributes
#     extended with :owner_member_id and :label.
# v1.0 (Session 36): Initial full CRUD.
#   - require_login + set_owner (cross-owner access guard).
#   - set_connection_group scoped to @owner.connection_groups.
#   - load_form_data: @connection_types alphabetical; @computers for owner.

class ConnectionGroupsController < ApplicationController
  before_action :require_login
  before_action :set_owner
  before_action :set_connection_group, only: %i[edit update destroy]

  # Legacy URL /owners/:owner_id/connection_groups — redirect to the new tab.
  def index
    redirect_to connections_owner_path(@owner), status: :moved_permanently
  end

  def new
    @connection_group = @owner.connection_groups.build

    # Pre-suggest the next owner_group_id so the owner sees the recommended
    # value and can override it before saving.
    @connection_group.owner_group_id = next_owner_group_id

    # Pre-build 2 blank member rows with sequential owner_member_ids (1, 2).
    # The before_validation callback on ConnectionMember would assign these on
    # save too, but pre-setting them here makes the suggested values visible in
    # the form fields immediately.
    @connection_group.connection_members.build(owner_member_id: 1)
    @connection_group.connection_members.build(owner_member_id: 2)

    load_form_data
  end

  def create
    @connection_group = @owner.connection_groups.build(connection_group_params)

    if @connection_group.save
      redirect_to connections_owner_path(@owner), notice: "Connection was successfully created."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # No pre-built blank row — the "+ Add port" button in the form handles
    # adding new ports via the Stimulus template when the user wants one.
    load_form_data
  end

  def update
    if @connection_group.update(connection_group_params)
      redirect_to connections_owner_path(@owner), notice: "Connection was successfully updated."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @connection_group.destroy
    redirect_to connections_owner_path(@owner), notice: "Connection was successfully deleted."
  end

  private

  # Verify the owner exists and belongs to the logged-in user.
  # Cross-owner access is blocked by redirecting to root.
  def set_owner
    @owner = Owner.find(params[:owner_id])
    redirect_to root_path unless Current.owner == @owner
  end

  # Scope to @owner's groups — prevents accessing another owner's groups by id.
  def set_connection_group
    @connection_group = @owner.connection_groups.find(params[:id])
  end

  # One higher than the highest owner_group_id this owner has used so far.
  def next_owner_group_id
    (@owner.connection_groups.maximum(:owner_group_id) || 0) + 1
  end

  def load_form_data
    # All connection types, alphabetical — for the type dropdown.
    @connection_types = ConnectionType.order(:name)

    # All devices belonging to this owner, ordered by model name then serial.
    # eager_load required for ORDER BY on the joined computer_models table.
    @computers = @owner.computers
                       .eager_load(:computer_model)
                       .order(Arel.sql("computer_models.name ASC, computers.serial_number ASC"))
  end

  def connection_group_params
    params.require(:connection_group).permit(
      :connection_type_id,
      :label,
      :owner_group_id,
      connection_members_attributes: [
        :id,
        :computer_id,
        :owner_member_id,
        :label,
        :_destroy
      ]
    )
  end
end
