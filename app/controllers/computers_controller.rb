# decor/app/controllers/computers_controller.rb - version 1.9
# v1.9 (Session 17): Fixed: appliances appeared on the Computers page when no
#   device_type filter param was present. On the computers route, device_type
#   now defaults to "computer" when the param is absent, so the Computers page
#   shows computers only by default. Explicit selection of "Appliance" in the
#   Type sidebar filter still works as expected.
# v1.8: Added set_device_context before_action; appliances route locks device_type.
# v1.7: Added device_type filter param to index.
# v1.6: destroy: capture owner before destroy; redirect to owner_path when source=owner.
# v1.5: condition_id → computer_condition_id references updated.

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

    # On the appliances route device_type is locked to "appliance".
    # On the computers route it comes from the Type filter param, defaulting to
    # "computer" so appliances never bleed onto the Computers page unintentionally.
    if @device_context == "appliance"
      computers = computers.where(device_type: "appliance")
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
  end

  def new
    @computer = Current.owner.computers.build
  end

  def create
    @computer = Current.owner.computers.build(computer_params)

    if @computer.save
      if params[:add_another]
        redirect_to new_computer_path, notice: "Computer was successfully created. Add another!"
      else
        redirect_to edit_computer_path(@computer), notice: "Computer was successfully created. You can now add components below."
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
      redirect_to computer_path(@computer), notice: "Computer was successfully updated."
    else
      @new_component = Current.owner.components.new(computer_id: @computer.id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Capture owner before destroy so we can redirect to their page if source=owner.
    owner = @computer.owner
    @computer.destroy

    if params[:source] == "owner"
      redirect_to owner_path(owner), notice: "Computer was successfully deleted."
    else
      redirect_to computers_path, notice: "Computer was successfully deleted."
    end
  end

  private

  # Reads the device_context route default (injected by config/routes.rb) and
  # sets all context-dependent instance variables used by the shared index views.
  def set_device_context
    if params[:device_context] == "appliance"
      @device_context = "appliance"
      @page_title     = "Appliances"
      @index_path     = appliances_path
      @turbo_tbody_id = "appliances"
      @load_more_id   = :load_more_appliances
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
    params.require(:computer).permit(:computer_model_id, :serial_number, :computer_condition_id, :run_status_id, :order_number, :history)
  end
end
