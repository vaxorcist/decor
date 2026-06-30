# decor/app/controllers/component_suggestions_controller.rb
# version 1.0
# v1.0 (Session 64): Component Suggestions Phase 2.
#   Owner-facing JSON endpoint for the order_number typeahead autocomplete.
#   NOT under the admin namespace — accessible to all logged-in members.
#
#   Route: GET /component_suggestions?query=<prefix>
#   Auth:  require_login — unauthenticated requests are redirected to login.
#   Response: JSON array of objects (order by order_number, limit 10):
#     [ { "order_number": "...", "description": "...", "category": "..." }, ... ]
#
#   The query param is matched as a prefix (LIKE 'prefix%') by the scope
#   ComponentSuggestion.matching defined on the model.
#
#   Empty / blank query: returns an empty JSON array without hitting the DB.
#   This prevents the dropdown from showing all suggestions on an empty input.
#
#   Security note: query param is never interpolated into raw SQL.
#   ComponentSuggestion.matching uses a parameterised LIKE with a bound value.

class ComponentSuggestionsController < ApplicationController
  before_action :require_login

  def index
    # Return an empty array immediately for blank queries — no DB hit needed,
    # and we don't want to show the full suggestion list on an empty field.
    if params[:query].blank?
      render json: []
      return
    end

    suggestions = ComponentSuggestion
                    .matching(params[:query])
                    .limit(10)
                    .pluck(:order_number, :description, :category)

    # Map the plucked arrays into named hashes for clear JSON structure.
    # Null description / category are preserved as null in the JSON so the
    # Stimulus controller can decide how to render missing optional fields.
    result = suggestions.map do |(order_number, description, category)|
      {
        order_number: order_number,
        description:  description,
        category:     category
      }
    end

    render json: result
  end
end
