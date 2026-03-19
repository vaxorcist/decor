# decor/app/controllers/computers_controller.rb
# version 1.17
# v1.17 (Session 34): show action now loads @connection_groups — the set of
#   ConnectionGroups this computer belongs to, eager-loading :connection_type
#   and computers: :computer_model to avoid N+1 queries on the show page.
#   The view iterates @connection_groups and filters peers in memory via reject
#   rather than where.not so the preloaded computers cache is used.
# v1.16 (Session 25): Extended set_device_context and index device_type filter
#   to handle device_context: "peripheral" (device_type value 2).
#   - set_device_context: added peripheral branch in case/when (replaces the
#     previous binary appliance/computer boolean).
#   - index: device_type filter now locks to "peripheral" on the peripherals
#     route, exactly mirroring the existing appliance lock.
# v1.15 (Session 21): Added barter_status filter to index.
# v1.14 (Session 20): Removed device_type selector from the form.
# v1.13 (Session 18): build() without device_type key fix.
# v1.10 (Session 18): Permitted :device_type; flash messages device_type-aware.
# v1.9  (Session 17): computers route defaults device_type to "computer".
# v1.8: set_device_context before_action; appliances route locks device_type.

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
    # On the computers route, fall back to the Type filter param or "computer"
    # so appliances and peripherals never bleed onto the Computers page.
    case @device_context
    when "appliance"
      computers = computers.where(device_type: "appliance")
    when "peripheral"
      computers = computers.where(device_type: "peripheral")
    else
      computers = computers.where(device_type: params[:device_type].presence || "computer")
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
    # Non-logged-in visitors see all items with no barter information displayed.
    # For logged-in users the default is "0+1" (no_barter and offered), which hides
    # "wanted" items (barter_status: 2) from the default listing because those records
    # may represent items not physically in the owner's collection.
    if logged_in?
      barter_filter = params[:barter_status].presence || "0+1"
      computers = case barter_filter
      when "0"   then computers.where(barter_status: 0)
      when "1"   then computers.where(barter_status: 1)
      when "2"   then computers.where(barter_status: 2)
      else            computers.where(barter_status: [0, 1])  # "0+1" and any unknown value
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

    # Load connection groups this computer belongs to, with all data needed
    # for the read-only connections section on the show page.
    #
    # Eager-load strategy (prevents N+1):
    #   :connection_type          — to display the type label or name
    #   computers: :computer_model — to display peer computer model names as links
    #
    # The view filters peer computers in memory (group.computers.reject { ... })
    # so the preloaded computers cache is used rather than firing per-row queries.
    @connection_groups = @computer.connection_groups
      .includes(:connection_type, computers: :computer_model)
      .order(:id)
  end

  def new
    # Build with the model default (computer: 0), then override device_type only
    # when the param is explicitly present (e.g. "Add Appliance" passes
    # device_type=appliance, "Add Peripheral" passes device_type=peripheral).
    # Passing device_type: nil to build() would override the enum default and
    # cause .capitalize to fail in the view — the key must be absent from the
    # hash entirely, not present with a nil value.
    @computer = Current.owner.computers.build
    @computer.device_type = params[:device_type] if params[:device_type].present?
  end

  def create
    @computer = Current.owner.computers.build(computer_params)

    if @computer.save
      # Use the record's actual device_type in the flash so "Appliance was
      # successfully created." / "Peripheral was successfully created." is shown
      # when those types are selected.
      device_label = @computer.device_type.capitalize

      if params[:add_another]
        redirect_to new_computer_path, notice: "#{device_label} was successfully created. Add another!"
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
    # Capture owner and device label before destroy — both are unavailable
    # after the record is deleted.
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

  # Reads the device_context route default (injected by config/routes.rb) and
  # sets all context-dependent instance variables used by the shared index views.
  # "computer"   (default) — /computers index
  # "appliance"            — /appliances index (device_type locked)
  # "peripheral"           — /peripherals index (device_type locked)
  def set_device_context
    case params[:device_context]
    when "appliance"
      @device_context = "appliance"
      @page_title     = "Appliances"
      @index_path     = appliances_path
      @turbo_tbody_id = "appliances"
      @load_more_id   = :load_more_appliances
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
      :device_type,   # hidden field only — type is fixed at creation, not editable via UI
      :barter_status  # select on new/edit forms; members only
    )
  end
end
