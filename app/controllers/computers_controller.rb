# decor/app/controllers/computers_controller.rb - version 1.13
# v1.13 (Session 18): new action: build() without device_type first, then assign
#   it only if the param is present. v1.12's .presence fix was wrong — nil.presence
#   is still nil, so build(device_type: nil) was still called and still overrode
#   the enum default. The key must be absent from the hash entirely, not present
#   with a nil value.
# v1.12 (Session 18): new action: params[:device_type].presence — incorrect fix.
# v1.11 (Session 18): new action reads params[:device_type] when building the record
#   so "Add Appliance" (which passes device_type=appliance) pre-sets the type correctly.
#   The heading (new.html.erb v1.4) and form selector (_form.html.erb v2.1) both derive
#   from @computer.device_type and update automatically — no view changes needed.
# v1.10 (Session 18): Permitted :device_type in computer_params so the new form
#   selector can set it on create/update. Flash messages in create, update, and
#   destroy are now device_type-aware (e.g. "Appliance was successfully updated."
#   instead of hardcoded "Computer"). device_label captured before destroy so the
#   message is available after the record is gone.
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
    # Build with the model default (computer: 0), then override device_type only
    # when the param is explicitly present (e.g. "Add Appliance" passes
    # device_type=appliance). Passing device_type: nil to build() would override
    # the enum default and cause .capitalize to fail in the view — the key must
    # be absent from the hash entirely, not present with a nil value.
    @computer = Current.owner.computers.build
    @computer.device_type = params[:device_type] if params[:device_type].present?
  end

  def create
    @computer = Current.owner.computers.build(computer_params)

    if @computer.save
      # Use the record's actual device_type in the flash so "Appliance was
      # successfully created." is shown when that type is selected.
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
    params.require(:computer).permit(
      :computer_model_id,
      :serial_number,
      :computer_condition_id,
      :run_status_id,
      :order_number,
      :history,
      :device_type   # permitted since Session 18: device_type selector on new/edit form
    )
  end
end
