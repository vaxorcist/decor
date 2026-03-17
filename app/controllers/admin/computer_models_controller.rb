# decor/app/controllers/admin/computer_models_controller.rb
# version 1.3
# v1.3 (Session 25): Extended set_device_context to handle device_context: "peripheral".
#   peripheral branch: @device_type_value = 2, route helpers use :peripheral_models.
#   No other changes — all actions are already driven entirely by the context
#   variables set here, so the peripheral page works without any further edits.
# v1.2: Added @create_path and @update_path_for to set_device_context so _form.html.erb
#   can pass an explicit url: to form_with, routing submissions to the correct resource.

module Admin
  class ComputerModelsController < BaseController
    before_action :set_device_context
    before_action :set_computer_model, only: %i[edit update destroy]

    def index
      # Scope to only models belonging to this device type.
      # Eager-load computers so the view can filter usage counts in memory.
      @computer_models = ComputerModel
                           .where(device_type: @device_type_value)
                           .order(:name)
                           .includes(:computers)
    end

    def new
      @computer_model = ComputerModel.new
    end

    def create
      @computer_model = ComputerModel.new(computer_model_params)
      # Stamp device_type from route context — not exposed in the form to
      # prevent clients from creating a record in the wrong list.
      @computer_model.device_type = @device_type_value

      if @computer_model.save
        redirect_to @index_path, notice: "#{@model_label} model was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @computer_model.update(computer_model_params)
        redirect_to @index_path, notice: "#{@model_label} model was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # restrict_with_error means destroy returns false (not raise) when
      # computers reference this model — check and redirect accordingly.
      if @computer_model.destroy
        redirect_to @index_path, notice: "#{@model_label} model was successfully deleted."
      else
        redirect_to @index_path,
                    alert: "Cannot delete: #{@computer_model.errors.full_messages.to_sentence}."
      end
    end

    private

    # Derives all context from the device_context param injected by the router.
    # "computer"   (default) → Computer Models page   (device_type: 0)
    # "appliance"            → Appliance Models page  (device_type: 1)
    # "peripheral"           → Peripheral Models page (device_type: 2)
    #
    # Sets:
    #   @model_label        — "Computer" / "Appliance" / "Peripheral"
    #   @model_label_plural — "Computers" / "Appliances" / "Peripherals"
    #   @device_type_key    — "computer" / "appliance" / "peripheral"
    #   @device_type_value  — 0 / 1 / 2
    #   @index_path         — collection index path
    #   @new_path           — new-record path
    #   @create_path        — collection POST path (form_with url: for new records)
    #   @update_path_for    — bound method (form_with url: for existing records)
    #   @edit_path_for      — bound method (Edit link in index)
    #   @delete_path_for    — bound method (Delete button in index)
    def set_device_context
      case params[:device_context]
      when "appliance"
        @model_label        = "Appliance"
        @model_label_plural = "Appliances"
        @device_type_key    = "appliance"
        @device_type_value  = 1
        @index_path         = admin_appliance_models_path
        @new_path           = new_admin_appliance_model_path
        @create_path        = admin_appliance_models_path
        @update_path_for    = method(:admin_appliance_model_path)
        @edit_path_for      = method(:edit_admin_appliance_model_path)
        @delete_path_for    = method(:admin_appliance_model_path)
      when "peripheral"
        @model_label        = "Peripheral"
        @model_label_plural = "Peripherals"
        @device_type_key    = "peripheral"
        @device_type_value  = 2
        @index_path         = admin_peripheral_models_path
        @new_path           = new_admin_peripheral_model_path
        @create_path        = admin_peripheral_models_path
        @update_path_for    = method(:admin_peripheral_model_path)
        @edit_path_for      = method(:edit_admin_peripheral_model_path)
        @delete_path_for    = method(:admin_peripheral_model_path)
      else
        # Default: "computer"
        @model_label        = "Computer"
        @model_label_plural = "Computers"
        @device_type_key    = "computer"
        @device_type_value  = 0
        @index_path         = admin_computer_models_path
        @new_path           = new_admin_computer_model_path
        @create_path        = admin_computer_models_path
        @update_path_for    = method(:admin_computer_model_path)
        @edit_path_for      = method(:edit_admin_computer_model_path)
        @delete_path_for    = method(:admin_computer_model_path)
      end
    end

    def set_computer_model
      @computer_model = ComputerModel.find(params[:id])
    end

    def computer_model_params
      # device_type is NOT permitted — stamped programmatically in #create.
      params.require(:computer_model).permit(:name)
    end
  end
end
