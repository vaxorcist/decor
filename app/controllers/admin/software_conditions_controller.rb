# decor/app/controllers/admin/software_conditions_controller.rb
# version 1.0
# Admin CRUD for the software_conditions lookup table.
#
# SoftwareCondition describes the completeness of a software item (e.g.
# "Complete", "Incomplete", "Subset"). It is admin-managed and analogous to
# ComponentCondition.
#
# IMPORTANT: The value column on software_conditions is named "name" — NOT
# "condition" like the legacy component_conditions table. This is an intentional
# cleaner convention for the new table (decided Session 43). Strong params,
# form fields, and validations all use :name.
#
# Destroy guard: SoftwareCondition uses dependent: :restrict_with_error, so
# destroy returns false when software_items still reference this record.

module Admin
  class SoftwareConditionsController < BaseController
    before_action :set_software_condition, only: %i[edit update destroy]

    # GET /admin/software_conditions
    # Eager-load software_items to avoid N+1 on the count column.
    def index
      @software_conditions = SoftwareCondition.order(:name).includes(:software_items)
    end

    # GET /admin/software_conditions/new
    def new
      @software_condition = SoftwareCondition.new
    end

    # POST /admin/software_conditions
    def create
      @software_condition = SoftwareCondition.new(software_condition_params)

      if @software_condition.save
        redirect_to admin_software_conditions_path, notice: "Software condition was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/software_conditions/:id/edit
    def edit
    end

    # PATCH/PUT /admin/software_conditions/:id
    def update
      if @software_condition.update(software_condition_params)
        redirect_to admin_software_conditions_path, notice: "Software condition was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/software_conditions/:id
    # destroy returns false (not raise) when restrict_with_error fires, so we
    # check the return value and show the model's error message as an alert.
    def destroy
      if @software_condition.destroy
        redirect_to admin_software_conditions_path, notice: "Software condition was successfully deleted."
      else
        redirect_to admin_software_conditions_path, alert: @software_condition.errors.full_messages.to_sentence
      end
    end

    private

    def set_software_condition
      @software_condition = SoftwareCondition.find(params[:id])
    end

    def software_condition_params
      # :name is the column (not :condition — see file header note)
      params.require(:software_condition).permit(:name, :description)
    end
  end
end
