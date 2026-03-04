# decor/app/controllers/admin/computer_models_controller.rb
# version 1.2
# Fix: form_with derives URL from model class, always resolving to
# /admin/computer_models regardless of context. Added @create_path and
# @update_path_for to set_device_context so _form.html.erb can pass an
# explicit url: to form_with, routing submissions to the correct resource.

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
    # "computer" (default) → Computer Models page.
    # "appliance"           → Appliance Models page.
    #
    # Sets:
    #   @model_label        — "Computer"  / "Appliance"  (titles, buttons, flash)
    #   @model_label_plural — "Computers" / "Appliances" (table column header)
    #   @device_type_key    — "computer"  / "appliance"  (enum string for in-memory filter)
    #   @device_type_value  — 0 / 1                      (integer for where + new-record stamp)
    #   @index_path         — collection index path      (redirects, Cancel)
    #   @new_path           — new-record path            (Add button)
    #   @create_path        — collection POST path       (form_with url: for new records)
    #   @update_path_for    — bound method               (form_with url: for existing records)
    #   @edit_path_for      — bound method               (Edit link in index)
    #   @delete_path_for    — bound method               (Delete button in index)
    def set_device_context
      appliance           = params[:device_context] == "appliance"
      @model_label        = appliance ? "Appliance"  : "Computer"
      @model_label_plural = appliance ? "Appliances" : "Computers"
      @device_type_key    = appliance ? "appliance"  : "computer"
      @device_type_value  = appliance ? 1 : 0
      @index_path         = appliance ? admin_appliance_models_path  : admin_computer_models_path
      @new_path           = appliance ? new_admin_appliance_model_path : new_admin_computer_model_path
      # @create_path: where the form POSTs for a new record
      @create_path        = appliance ? admin_appliance_models_path  : admin_computer_models_path
      # @update_path_for: where the form PATCHes for an existing record
      @update_path_for    = method(appliance ? :admin_appliance_model_path   : :admin_computer_model_path)
      @edit_path_for      = method(appliance ? :edit_admin_appliance_model_path : :edit_admin_computer_model_path)
      @delete_path_for    = method(appliance ? :admin_appliance_model_path   : :admin_computer_model_path)
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
