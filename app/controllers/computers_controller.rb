# decor/app/controllers/computers_controller.rb - version 1.5
# Updated all condition_id references → computer_condition_id following the
# conditions → computer_conditions table/model rename (Session 7, Feb 25, 2026):
#   - includes(:condition)           → includes(:computer_condition)
#   - params[:condition_id]          → params[:computer_condition_id]
#   - permit(:condition_id)          → permit(:computer_condition_id)

class ComputersController < ApplicationController
  before_action :set_computer, only: %i[show edit update destroy]
  before_action :ensure_computer_belongs_to_current_owner, only: %i[edit update destroy]

  def index
    computers = Computer.includes(:owner, :computer_model, :computer_condition, :run_status).search(params[:query])

    # Filter by owner if owner_id parameter is present (e.g., from owners page)
    if params[:owner_id].present?
      computers = computers.where(owner_id: params[:owner_id])
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
        # "Create and add another" still goes to new computer form
        redirect_to new_computer_path, notice: "Computer was successfully created. Add another!"
      else
        # Go directly to edit page so the user can add components immediately
        redirect_to edit_computer_path(@computer), notice: "Computer was successfully created. You can now add components below."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Blank component pre-assigned to this computer — used by the Add sub-form
    @new_component = Current.owner.components.new(computer_id: @computer.id)

    # If component_id param is present, load that component for inline editing.
    # Scoped to this computer's components so users cannot edit other computers' components.
    if params[:component_id].present?
      @edit_component = @computer.components.find_by(id: params[:component_id])
    end
  end

  def update
    if @computer.update(computer_params)
      redirect_to computer_path(@computer), notice: "Computer was successfully updated."
    else
      # Re-populate sub-form instance variables so the edit page renders correctly on failure
      @new_component = Current.owner.components.new(computer_id: @computer.id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @computer.destroy
    redirect_to computers_path, notice: "Computer was successfully deleted."
  end

  private

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
