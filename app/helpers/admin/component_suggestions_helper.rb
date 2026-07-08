# decor/app/helpers/admin/component_suggestions_helper.rb
# version 1.0
# Session 67: Phase 4 item 4 — supports the new filter sidebar on
# decor/app/views/admin/component_suggestions/index.html.erb.
#
# Follows the established helper pattern used by SoftwareItemsHelper for the
# software_items filter sidebar (options + selected-value pairs, one method
# each, consumed directly by form.select in the _filters.html.erb partial).
#
# Only one filter field needs helper support here — the "manual" flag select.
# The order_number search field reads params[:query] directly in the view,
# exactly as software_items/_filters.html.erb does for its own query field.

module Admin::ComponentSuggestionsHelper
  # Options for the "Manual" filter select. Raw enum values ("added" /
  # "modified") are used as the option values so the controller's
  # `where(manual: params[:manual])` can match them directly via Rails'
  # built-in enum-aware `where` translation (see
  # Admin::ComponentSuggestionsController#index).
  def component_suggestion_filter_manual_options
    [
      ["Added manually",   "added"],
      ["Modified manually", "modified"]
    ]
  end

  # Currently-selected value for the "Manual" filter select, or nil for the
  # include_blank "Any" option (all rows, regardless of manual flag).
  def component_suggestion_filter_manual_selected
    params[:manual].presence
  end
end
