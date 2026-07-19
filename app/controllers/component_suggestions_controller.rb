# decor/app/controllers/component_suggestions_controller.rb
# version 1.1
# v1.1 (Session 68): Edit Component UI change — raised the result limit from
#   10 to 100 so the typeahead dropdown can show significantly more matches
#   (e.g. 43 existing suggestions for a prefix were previously truncated to
#   the first 10). The dropdown itself becomes scrollable with a viewport-
#   aware max-height on the JS side (see component_suggestion_controller.js
#   v1.1) — this endpoint only needed the .limit(10) -> .limit(100) change.
#   NOTE: the existing owner-facing controller test (component_suggestions_
#   controller_test.rb v1.0, Session 64) is documented in DECOR_PROJECT.md as
#   covering "the 10-result limit" — that assertion will need updating to
#   match the new limit of 100. The test file was not available this
#   session; flagging as a pending follow-up rather than guessing its exact
#   assertion and editing blind.
# v1.0 (Session 64): Component Suggestions Phase 2.
#   Owner-facing JSON endpoint for the order_number typeahead autocomplete.
#   NOT under the admin namespace — accessible to all logged-in members.
#
#   Route: GET /component_suggestions?query=<prefix>
#   Auth:  require_login — unauthenticated requests are redirected to login.
#   Response: JSON array of objects (order by order_number, limit 100):
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
                    .limit(100)
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
