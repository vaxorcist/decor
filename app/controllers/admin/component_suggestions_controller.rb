# decor/app/controllers/admin/component_suggestions_controller.rb
# version 1.2
# Session 67 (continued): index action rewritten now that the actual
#   Pagination concern (decor/app/controllers/concerns/pagination.rb) has
#   been reviewed. Two things that changed the implementation from v1.1's
#   assumption:
#     1. paginate(scope) is NOT a plain data-fetch call — it internally does
#        `respond_to { |format| format.turbo_stream; format.html }` and
#        therefore renders the response itself. This means every ivar the
#        view needs (@page_title, @turbo_tbody_id, @load_more_id,
#        @index_path) MUST be set BEFORE calling paginate — paginate is
#        effectively the last line of the action, not just a data-loading step.
#     2. The concern sets @page (via set_page_and_extract_portion_from) —
#        confirmed NOT @component_suggestions. The view iterates
#        @page.records, matching the established software_items/computers/
#        components pattern (DECOR_PROJECT.md "Geared Pagination Pattern").
#   Matches the confirmed decision (Session 67) to follow the existing
#   infinite-scroll "Load more" pattern rather than classic pagination.
# Session 67: Phase 4 changes (manual flag tracking, download_manual action) —
#   see v1.1 history below, unchanged in this revision.
# Session 63: Phase 1 of Component Suggestions feature.
#
# Admin CRUD for the component_suggestions lookup table.
#
# ComponentSuggestion holds validated order numbers that power the typeahead
# autocomplete on the components form (Phase 2). Admins manage this table
# directly; regular users cannot access it.
#
# Strong params: order_number, description, category. "manual" is deliberately
# NOT in the permitted list — it is only ever set by this controller's own
# create/update logic, never by user-supplied form data.

module Admin
  class ComponentSuggestionsController < BaseController
    before_action :set_component_suggestion, only: %i[edit update destroy]

    # GET /admin/component_suggestions
    # Ordered alphabetically by order_number. Filterable by order_number
    # substring (params[:query]) and by the manual flag (params[:manual] —
    # one of "added" / "modified", or blank for all rows). Paginated via the
    # project's established geared_pagination "Load more" infinite-scroll
    # pattern (see file header note above for exactly how the ivars and the
    # render are wired together).
    def index
      @page_title     = "Component Suggestions"
      @turbo_tbody_id = "component_suggestions"
      @load_more_id   = "load_more_component_suggestions"

      # Preserve only the filter params that are actually present, so the
      # "Load more" link's URL stays clean when no filter is active — mirrors
      # the documented behavior of software_items' @index_path
      # ("software_items_path with current filter params preserved").
      @index_path = admin_component_suggestions_path(
        query:  params[:query].presence,
        manual: params[:manual].presence
      )

      suggestions = ComponentSuggestion.order(:order_number)
      suggestions = suggestions.order_number_contains(params[:query])  if params[:query].present?
      suggestions = suggestions.where(manual: params[:manual])        if params[:manual].present?

      # Last line, deliberately not assigned to anything — paginate() sets
      # @page itself AND renders the response (format.turbo_stream / format.html).
      paginate(suggestions)
    end

    # GET /admin/component_suggestions/new
    def new
      @component_suggestion = ComponentSuggestion.new
    end

    # POST /admin/component_suggestions
    def create
      @component_suggestion = ComponentSuggestion.new(component_suggestion_params)

      # New rows created through the admin form are always "added" — this is
      # permanent (Session 66 confirmed decision: an "added" row never becomes
      # "modified", even on later edits — see the update action below, which
      # only sets "modified" when manual is currently nil).
      @component_suggestion.manual = "added"

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
      # Only promote an untouched bulk-import row (manual: nil) to "modified".
      # A row that is already "added" or already "modified" keeps its current
      # value — this is what makes "added" a permanent, one-way flag while
      # still letting a plain bulk-import row become "modified" the first
      # time someone hand-edits it.
      @component_suggestion.manual = "modified" if @component_suggestion.manual.nil?

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

    # GET /admin/component_suggestions/download_manual
    # CSV of every manually-touched row ("added" + "modified" together).
    # See ManualComponentSuggestionsExportService for the full rationale —
    # this is the required backup step before a re-import, since the import
    # service deletes all rows (including manual ones) unconditionally.
    def download_manual
      send_data ManualComponentSuggestionsExportService.export,
                filename: "component_suggestions_manual_#{Date.current.iso8601}.csv",
                type: "text/csv"
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
