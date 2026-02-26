# decor/app/controllers/admin/conditions_controller.rb
# version 1.2
# Updated flash messages to say "Computer condition" (was "Condition") to
# distinguish from the new component conditions managed by
# Admin::ComponentConditionsController.

module Admin
  class ConditionsController < BaseController
    before_action :set_condition, only: %i[edit update destroy]

    def index
      @conditions = ComputerCondition.order(:name).includes(:computers)
    end

    def new
      @condition = ComputerCondition.new
    end

    def create
      @condition = ComputerCondition.new(condition_params)

      if @condition.save
        redirect_to admin_conditions_path, notice: "Computer condition was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @condition.update(condition_params)
        redirect_to admin_conditions_path, notice: "Computer condition was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @condition.destroy
      redirect_to admin_conditions_path, notice: "Computer condition was successfully deleted."
    end

    private

    def set_condition
      @condition = ComputerCondition.find(params[:id])
    end

    def condition_params
      params.require(:condition).permit(:name)
    end
  end
end
