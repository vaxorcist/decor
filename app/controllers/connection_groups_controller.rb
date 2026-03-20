# decor/app/controllers/connection_groups_controller.rb
# version 1.0
# Session 36: Part 4 — Owner ConnectionGroup CRUD.
#
# Full CRUD for an owner's own connection groups, nested under /owners/:owner_id/.
# Route helpers (prefix: owner_connection_group(s)):
#   owner_connection_groups_path(@owner)          GET  index
#   new_owner_connection_group_path(@owner)       GET  new
#   owner_connection_groups_path(@owner)          POST create
#   edit_owner_connection_group_path(@owner, @cg) GET  edit
#   owner_connection_group_path(@owner, @cg)      PATCH/DELETE update/destroy
#
# Security:
#   - require_login:  redirects to new_session_path if not authenticated.
#   - set_owner:      finds Owner by params[:owner_id] and verifies it equals
#                     Current.owner; redirects to root_path with alert if not.
#                     Owners can only manage their own groups — no cross-owner
#                     access is possible regardless of the URL.
#   - set_connection_group: scopes the lookup to @owner.connection_groups so an
#                     owner cannot access another owner's group even if they
#                     supply a valid group id belonging to someone else.

class ConnectionGroupsController < ApplicationController
  before_action :require_login
  before_action :set_owner
  before_action :set_connection_group, only: %i[edit update destroy]

  # GET /owners/:owner_id/connection_groups
  # Lists all connection groups belonging to @owner, eager-loading connection_type
  # and the computers + their models (avoids N+1 on the members display).
  def index
    @connection_groups = @owner.connection_groups
                               .includes(:connection_type, computers: :computer_model)
                               .order(:created_at)
  end

  # GET /owners/:owner_id/connection_groups/new
  # Pre-builds 2 blank member rows so the form always shows the minimum
  # required dropdowns without the user having to click "Add member" first.
  def new
    @connection_group = @owner.connection_groups.build
    2.times { @connection_group.connection_members.build }
    load_form_data
  end

  # POST /owners/:owner_id/connection_groups
  def create
    @connection_group = @owner.connection_groups.build(connection_group_params)
    if @connection_group.save
      redirect_to owner_connection_groups_path(@owner),
                  notice: "Connection group was successfully created."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  # GET /owners/:owner_id/connection_groups/:id/edit
  # Appends one blank member row so there is always an empty dropdown available
  # for adding a new device without clicking "Add member".
  def edit
    @connection_group.connection_members.build
    load_form_data
  end

  # PATCH /owners/:owner_id/connection_groups/:id
  def update
    if @connection_group.update(connection_group_params)
      redirect_to owner_connection_groups_path(@owner),
                  notice: "Connection group was successfully updated."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /owners/:owner_id/connection_groups/:id
  # Destroys the group; dependent: :delete_all on the model removes all member
  # rows at the DB level (no Ruby callbacks needed for this direction).
  def destroy
    @connection_group.destroy
    redirect_to owner_connection_groups_path(@owner),
                notice: "Connection group was successfully deleted."
  end

  private

  # Finds the owner by params[:owner_id] and enforces that only the logged-in
  # owner can access their own groups. Redirects to root if the URL owner_id
  # does not match Current.owner (prevents horizontal privilege escalation).
  def set_owner
    @owner = Owner.find(params[:owner_id])
    unless @owner == Current.owner
      redirect_to root_path, alert: "Not authorised."
    end
  end

  # Scopes the lookup to @owner.connection_groups so no group belonging to
  # another owner can be fetched even if its id is guessed.
  def set_connection_group
    @connection_group = @owner.connection_groups.find(params[:id])
  end

  # Loads data needed by both new and edit forms:
  #   @connection_types — all types ordered by name for the type dropdown.
  #   @computers        — the owner's computers ordered by model name then serial,
  #                       for the member selection dropdowns.
  # Arel.sql required: ORDER BY references a joined table column (computer_models.name).
  def load_form_data
    @connection_types = ConnectionType.order(:name)
    @computers = @owner.computers
                       .joins(:computer_model)
                       .includes(:computer_model)
                       .order(Arel.sql("computer_models.name ASC, computers.serial_number ASC"))
  end

  # Strong parameters: permit label, connection_type_id, and nested member
  # attributes. _destroy allows removal of existing members via the form.
  def connection_group_params
    params.require(:connection_group).permit(
      :connection_type_id,
      :label,
      connection_members_attributes: %i[id computer_id _destroy]
    )
  end
end
