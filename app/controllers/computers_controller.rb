# decor/app/controllers/computers_controller.rb
# version 1.22
# v1.22 (Session 52): Simplified index device_type branch.
#   The Type filter (Computer / Peripheral selector) was removed from the
#   _filters.html.erb sidebar. The else branch previously read
#   params[:device_type].presence || "computer" to honour that filter param.
#   Now that no UI can submit device_type on the Computers page, the branch
#   unconditionally scopes to device_type: "computer".
#   Dead param support removed; behaviour for normal requests is unchanged.
#
# v1.21 (Session 52): Bug fix — "Create and add another" now preserves device_type.
#   The redirect to new_computer_path was missing device_type:, so creating a
#   peripheral and clicking "Create and add another" landed on /computers/new
#   (Add computer) instead of /computers/new?device_type=peripheral.
#   Fix: pass device_type: @computer.device_type to new_computer_path so the
#   new action can pre-set @computer.device_type correctly.
#
# v1.20 (Session 47): Software feature Session E.
#   show action: added @software_items eager-load.
#   Loads software installed on this computer/peripheral for the read-only
#   Software section added to computers/show.html.erb.
#   Ordered by created_at ascending — no join needed, no Arel.sql required.
#   includes :software_name and :software_condition to avoid N+1 in the table.
#
# v1.19 (Session 41): Appliances → Peripherals merger Phase 2.
#   Removed "appliance" branch from set_device_context — the appliances route is
#   gone; device_context: "appliance" no longer exists.
#   Removed "appliance" when branch from index device_type filter for the same reason.
#   Peripherals now covers all device_type_peripheral? records.
# v1.18 (Session 38): show action — updated @connection_groups eager-loading.
# v1.17 (Session 34): show action now loads @connection_groups with eager-loading.
# v1.16 (Session 25): Extended set_device_context and index device_type filter
#   to handle device_context: "peripheral" (device_type value 2).
# v1.15 (Session 21): Added barter_status filter to index.
# v1.14 (Session 20): Removed device_type selector from the form.
# v1.10 (Session 18): Permitted :device_type; flash messages device_type-aware.

class ComputersController < ApplicationController
  before_action :set_device_context
  before_action :set_computer, only: %i[show edit update destroy]
  before_action :ensure_computer_belongs_to_current_owner, only: %i[edit update destroy]

  def index
    computers = Computer.includes(:owner, :computer_model, :computer_condition, :run_status).search(params[:query])

    # Filter by owner if owner_id parameter is present (e.g., from owners page)
    if params[:owner_id].present?
      computers = computers.where(owner_id: params[:owner_id])
    end

    # Lock device_type to the route context on dedicated type pages.
    # The Type filter was removed in Session 52 — no UI can submit device_type
    # on the Computers page, so the else branch unconditionally scopes to
    # device_type: "computer" rather than reading params[:device_type].
    case @device_context
    when "peripheral"
      computers = computers.where(device_type: "peripheral")
    else
      computers = computers.where(device_type: "computer")
    end

    if params[:model].present?
      model = ComputerModel.find(params[:model])
      computers = computers.where(computer_model: model)
    end

    if params[:computer_condition_id].present?
      computers = computers.where(computer_condition_id: params[:computer_condition_id])
    end

    if params[:run_status_id].present?
      computers = computers.where(run_status_id: params[:run_status_id])
    end

    # Barter status filter — members only.
    if logged_in?
      barter_filter = params[:barter_status].presence || "0+1"
      computers = case barter_filter
      when "0"   then computers.where(barter_status: 0)
      when "1"   then computers.where(barter_status: 1)
      when "2"   then computers.where(barter_status: 2)
      else            computers.where(barter_status: [0, 1])
      end
    end

    computers = case params[:sort]
    when "added_asc"  then computers.order(created_at: :asc)
    when "added_desc" then computers.order(created_at: :desc)
    when "model_asc"  then computers.joins(:computer_model).order("computer_models.name ASC")
    when "model_desc" then computers.joins(:computer_model).order("computer_models.name DESC")
    else
      computers.order(created_at: :desc)
    end

    paginate computers
  end

  def show
    @components = @computer.components.includes(:component_type)

    # Load connection groups this computer belongs to.
    #
    # Eager-load strategy (prevents N+1 for the multi-row connections table):
    #   :connection_type                            — type name column
    #   connection_members: { computer: :computer_model } — port rows with device names
    #
    # The view iterates group.connection_members.sort_by(&:owner_member_id) using
    # the preloaded in-memory collection — no extra DB query per group.
    # Ordered by owner_group_id to respect the owner's numbering scheme.
    @connection_groups = @computer.connection_groups
      .includes(:connection_type, connection_members: { computer: :computer_model })
      .order(:owner_group_id)

    # Load software installed on this computer/peripheral (Session E).
    #
    # Eager-loads :software_name and :software_condition to prevent N+1 in the
    # Software section table. computer_id is nullable on software_items, so only
    # items explicitly linked to this computer are included — unattached items
    # (computer_id: nil) are excluded automatically by the association scope.
    #
    # Ordered by created_at ascending — stable, predictable order without a join.
    @software_items = @computer.software_items
      .includes(:software_name, :software_condition)
      .order(created_at: :asc)
  end

  def new
    @computer = Current.owner.computers.build
    @computer.device_type = params[:device_type] if params[:device_type].present?
  end

  def create
    @computer = Current.owner.computers.build(computer_params)

    if @computer.save
      device_label = @computer.device_type.capitalize

      if params[:add_another]
        # Forward device_type so the next new-form opens as the same device kind
        # (computer or peripheral) rather than always defaulting to /computers/new.
        redirect_to new_computer_path(device_type: @computer.device_type),
                    notice: "#{device_label} was successfully created. Add another!"
      else
        redirect_to edit_computer_path(@computer), notice: "#{device_label} was successfully created. You can now add components below."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @new_component = Current.owner.components.new(computer_id: @computer.id)

    if params[:component_id].present?
      @edit_component = @computer.components.find_by(id: params[:component_id])
    end
  end

  def update
    if @computer.update(computer_params)
      redirect_to computer_path(@computer), notice: "#{@computer.device_type.capitalize} was successfully updated."
    else
      @new_component = Current.owner.components.new(computer_id: @computer.id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    owner        = @computer.owner
    device_label = @computer.device_type.capitalize
    @computer.destroy

    if params[:source] == "owner"
      redirect_to owner_path(owner), notice: "#{device_label} was successfully deleted."
    else
      redirect_to computers_path, notice: "#{device_label} was successfully deleted."
    end
  end

  private

  # Sets page context from the device_context router default.
  # "peripheral" → Peripherals page (device_type: 2); covers all peripheral records
  #               (formerly also appliances, which were merged into peripherals in
  #               Session 41).
  # default      → Computers page (device_type: 0).
  def set_device_context
    case params[:device_context]
    when "peripheral"
      @device_context = "peripheral"
      @page_title     = "Peripherals"
      @index_path     = peripherals_path
      @turbo_tbody_id = "peripherals"
      @load_more_id   = :load_more_peripherals
    else
      @device_context = "computer"
      @page_title     = "Computers"
      @index_path     = computers_path
      @turbo_tbody_id = "computers"
      @load_more_id   = :load_more_computers
    end
  end

  def set_computer
    @computer = Computer.find(params[:id])
  end

  def ensure_computer_belongs_to_current_owner
    require_owner(@computer.owner)
  end

  def computer_params
    params.require(:computer).permit(
      :computer_model_id,
      :serial_number,
      :computer_condition_id,
      :run_status_id,
      :order_number,
      :history,
      :device_type,
      :barter_status
    )
  end
end
