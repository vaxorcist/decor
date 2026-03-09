# decor/app/controllers/components_controller.rb
# version 1.7
# v1.7 (Session 21): Added barter_status filter to index.
#   - Only applied when the user is logged in (logged_in? helper from authentication.rb).
#   - Default for logged-in users: "0+1" (no_barter + offered).
#   - Non-logged-in users: no barter filter applied; barter data hidden in views.
#   - Filter param: barter_status = "0", "0+1", "1", or "2".
#   - :barter_status added to strong params (component_params).
#   - :component_category added to strong params (was missing — needed for form).
# v1.6 (Session 19): Added sort case "order_asc".
# v1.5: source=computer_show redirect.
# v1.4: source=owner redirect; capture owner/computer before destroy.

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

    # Barter status filter — members only.
    # Non-logged-in visitors see all items with no barter information displayed.
    # Default for logged-in users: "0+1" (no_barter + offered). This hides "wanted"
    # items from the default listing since those records may not represent items the
    # owner physically possesses.
    if logged_in?
      barter_filter = params[:barter_status].presence || "0+1"
      components = case barter_filter
      when "0"   then components.where(barter_status: 0)
      when "1"   then components.where(barter_status: 1)
      when "2"   then components.where(barter_status: 2)
      else            components.where(barter_status: [0, 1])  # "0+1" and any unknown value
      end
    end

    # Sort by owner joins the owners table to sort by user_name alphabetically.
    # Sort by type joins the component_types table to sort by name alphabetically.
    # Sort by order_asc uses Arel.sql() because NULLS LAST is a SQL keyword phrase
    # that Rails rejects as a bare string in .order(). order_number lives on the
    # components table so no join is needed.
    components = case params[:sort]
    when "added_asc"  then components.order(created_at: :asc)
    when "added_desc" then components.order(created_at: :desc)
    when "owner_asc"  then components.joins(:owner).order("owners.user_name asc")
    when "type_asc"   then components.joins(:component_type).order("component_types.name asc")
    when "order_asc"  then components.order(Arel.sql("components.order_number ASC NULLS LAST"))
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
    # source param controls where the user lands after deletion.
    owner    = @component.owner
    computer = @component.computer

    @component.destroy

    if params[:source] == "owner"
      redirect_to owner_path(owner), notice: "Component was successfully deleted."
    elsif params[:source] == "computer_show" && computer.present?
      redirect_to computer_path(computer), notice: "Component was successfully deleted."
    elsif params[:source] == "computer" && computer.present?
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
      :component_category, # enum — integral/peripheral; editable on form
      :serial_number,
      :order_number,
      :description,
      :barter_status       # select on new/edit forms; members only
    )
  end
end
