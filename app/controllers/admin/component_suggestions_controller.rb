# decor/app/controllers/admin/component_suggestions_controller.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Admin CRUD for the component_suggestions lookup table.
#
# ComponentSuggestion holds validated order numbers that power the typeahead
# autocomplete on the components form (Phase 2). Admins manage this table
# directly; regular users cannot access it.
#
# Pattern: identical to Admin::SoftwareNamesController.
#   - index: paginated list (geared_pagination), ordered by order_number.
#   - new/create/edit/update: standard Rails CRUD.
#   - destroy: no dependent records, so destroy always succeeds.
#     (ComponentSuggestion has no has_many — it is a pure lookup table.)
#     Kept the standard redirect-with-notice pattern; no restrict_with_error guard needed.
#
# Strong params: order_number, description, category.
# All three are validated at the model level.

module Admin
  class ComponentSuggestionsController < BaseController
    before_action :set_component_suggestion, only: %i[edit update destroy]

    # GET /admin/component_suggestions
    # Ordered alphabetically by order_number.
    def index
      @component_suggestions = ComponentSuggestion.order(:order_number)
    end

    # GET /admin/component_suggestions/new
    def new
      @component_suggestion = ComponentSuggestion.new
    end

    # POST /admin/component_suggestions
    def create
      @component_suggestion = ComponentSuggestion.new(component_suggestion_params)

      if @component_suggestion.save
        redirect_to admin_component_suggestions_path,
                    notice: "Component suggestion was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/component_suggestions/:id/edit
    def edit
    end

    # PATCH/PUT /admin/component_suggestions/:id
    def update
      if @component_suggestion.update(component_suggestion_params)
        redirect_to admin_component_suggestions_path,
                    notice: "Component suggestion was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/component_suggestions/:id
    # ComponentSuggestion has no dependents — destroy always succeeds.
    def destroy
      @component_suggestion.destroy
      redirect_to admin_component_suggestions_path,
                  notice: "Component suggestion was successfully deleted."
    end

    private

    def set_component_suggestion
      @component_suggestion = ComponentSuggestion.find(params[:id])
    end

    def component_suggestion_params
      params.require(:component_suggestion).permit(:order_number, :description, :category)
    end
  end
end
