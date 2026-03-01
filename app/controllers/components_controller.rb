# decor/app/controllers/components_controller.rb - version 1.5
# destroy: added source=computer_show branch → redirects to computer_path (show page).
#   Used when deleting a component from computers/show so the user stays on that page.
#   source=computer (edit page) behaviour unchanged.
# Previous (v1.4): source=owner branch added; capture owner/computer before destroy.

class ComponentsController < ApplicationController
  before_action :set_component, only: %i[show edit update destroy]
  before_action :ensure_component_belongs_to_current_owner, only: %i[edit update destroy]

  def index
    components = Component.includes(:owner, :component_type, :computer).search(params[:query])

    if params[:component_type].present?
      component_type = ComponentType.find(params[:component_type])
      components = components.where(component_type: component_type)
    end

    if params[:computer_model].present?
      if params[:computer_model] == "unassigned"
        components = components.where(computer_id: nil)
      else
        computer_model = ComputerModel.find(params[:computer_model])
        components = components.joins(computer: :computer_model).where(computer_models: { id: computer_model.id })
      end
    end

    # Sort by owner joins the owners table to sort by user_name alphabetically.
    # Sort by type joins the component_types table to sort by name alphabetically.
    # Both use joins (not includes) because the ORDER BY clause references the joined table.
    components = case params[:sort]
    when "added_asc"  then components.order(created_at: :asc)
    when "added_desc" then components.order(created_at: :desc)
    when "owner_asc"  then components.joins(:owner).order("owners.user_name asc")
    when "type_asc"   then components.joins(:component_type).order("component_types.name asc")
    else
      components.order(created_at: :desc)
    end

    paginate components
  end

  def show
  end

  def new
    @component = Current.owner.components.new(computer_id: params[:computer_id])
  end

  def create
    @component = Current.owner.components.build(component_params)

    if @component.save
      if params[:source] == "computer" && @component.computer_id.present?
        # Redirect back to the computer edit page when adding from embedded form
        redirect_to edit_computer_path(@component.computer), notice: "Component was successfully created."
      elsif params[:add_another]
        redirect_to new_component_path(computer_id: @component.computer_id), notice: "Component was successfully created. Add another!"
      else
        redirect_to component_path(@component), notice: "Component was successfully created."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @component.update(component_params)
      if params[:source] == "computer" && @component.computer_id.present?
        # Redirect back to the computer edit page when editing from embedded form
        redirect_to edit_computer_path(@component.computer), notice: "Component was successfully updated."
      else
        redirect_to component_path(@component), notice: "Component was successfully updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Capture owner and computer before destroy for redirect decisions.
    # source param controls where the user lands after deletion:
    #   source=owner         → owner show page   (deleted from owners/show)
    #   source=computer_show → computer show page (deleted from computers/show)
    #   source=computer      → computer edit page (deleted from embedded edit form)
    #   (none)               → components index
    owner    = @component.owner
    computer = @component.computer

    @component.destroy

    if params[:source] == "owner"
      redirect_to owner_path(owner), notice: "Component was successfully deleted."
    elsif params[:source] == "computer_show" && computer.present?
      # Stay on the computer show page after deleting from computers/show
      redirect_to computer_path(computer), notice: "Component was successfully deleted."
    elsif params[:source] == "computer" && computer.present?
      # Redirect back to the computer edit page when deleting from embedded form
      redirect_to edit_computer_path(computer), notice: "Component was successfully deleted."
    else
      redirect_to components_path, notice: "Component was successfully deleted."
    end
  end

  private

  def set_component
    @component = Component.find(params[:id])
  end

  def ensure_component_belongs_to_current_owner
    require_owner(@component.owner)
  end

  def component_params
    params.require(:component).permit(
      :component_type_id,
      :computer_id,
      :component_condition_id,
      :serial_number,
      :order_number,
      :description
    )
  end
end
