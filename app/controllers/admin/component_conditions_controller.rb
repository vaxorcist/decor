# decor/app/controllers/admin/component_conditions_controller.rb
# version 1.0
# Admin CRUD for the component_conditions lookup table.
#
# Unlike Admin::ConditionsController (which manages ComputerCondition via a
# mismatched route name :conditions), this controller has a clean class-to-route
# match: ComponentCondition → resources :component_conditions. No url:/scope:
# workaround is required in the form partial.
#
# The value column on component_conditions is named "condition" (not "name") —
# strong params, form fields, and validations all use :condition accordingly.

module Admin
  class ComponentConditionsController < BaseController
    before_action :set_component_condition, only: %i[edit update destroy]

    def index
      # Eager-load components to avoid N+1 on the count column
      @component_conditions = ComponentCondition.order(:condition).includes(:components)
    end

    def new
      @component_condition = ComponentCondition.new
    end

    def create
      @component_condition = ComponentCondition.new(component_condition_params)

      if @component_condition.save
        redirect_to admin_component_conditions_path, notice: "Component condition was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @component_condition.update(component_condition_params)
        redirect_to admin_component_conditions_path, notice: "Component condition was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # ComponentCondition uses dependent: :restrict_with_error, so destroy will
      # fail (return false) when components still reference this record.
      # We redirect with an alert in that case rather than raising an exception.
      if @component_condition.destroy
        redirect_to admin_component_conditions_path, notice: "Component condition was successfully deleted."
      else
        redirect_to admin_component_conditions_path, alert: @component_condition.errors.full_messages.to_sentence
      end
    end

    private

    def set_component_condition
      @component_condition = ComponentCondition.find(params[:id])
    end

    def component_condition_params
      params.require(:component_condition).permit(:condition)
    end
  end
end
