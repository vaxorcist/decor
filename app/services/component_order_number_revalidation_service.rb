# decor/app/services/component_order_number_revalidation_service.rb
# version 1.0
# NEW (Session 65): Bulk re-sync of Component#order_number_verified against the
#   current component_suggestions table. Backs the admin "Re-validate Order
#   Numbers" dropdown action (Admin::ComponentOrderNumbersController#revalidate).
#
# Why this exists: order_number_verified is normally set client-side, once,
#   at the moment an owner accepts a typeahead suggestion (see
#   component_suggestion_controller.js, Session 64). It is never re-checked
#   after that. If an admin later adds a NEW ComponentSuggestion for a value
#   an owner had already typed in freely (order_number_verified: false), that
#   existing component has no way to become verified without the owner
#   re-visiting and re-submitting the form. This service performs that
#   re-sync in bulk, across every component, on demand.
#
# Rule applied per component (confirmed design decision):
#   order_number_verified should be true  IFF component.order_number is present
#                                          AND that exact value exists in
#                                          component_suggestions.order_number.
#   Everything else (blank order_number, or a value with no matching
#   ComponentSuggestion) should be false.
#
# This is symmetric — it can also flip a component from verified to
#   unverified, e.g. if a ComponentSuggestion was deleted or its order_number
#   edited after a component had already been verified against the old value.
#
# Runs immediately / synchronously (no background job) — confirmed design
#   decision. Applies immediately with no preview step; safe to re-run at any
#   time since it always converges to the same correct state (idempotent).
#
# Uses update_column (skips validations/callbacks) deliberately: this touches
#   a single boolean flag as a data-integrity sync, not a user-facing form
#   edit, so re-running the model's other validations (e.g. the serial_number
#   uniqueness scope in decor/app/models/component.rb) for every row would be
#   both unnecessary and needlessly slow.

class ComponentOrderNumberRevalidationService
  # @return [Hash] counts for the flash message:
  #   { verified_count:, unverified_count:, unchanged_count: }
  def self.call
    # Single query, held in memory as a Set for O(1) per-component lookup.
    # component_suggestions.order_number carries a UNIQUE index (see
    # ComponentSuggestion model, Session 63), so this Set has no duplicates
    # and its size is bounded by the admin-managed suggestions table, not by
    # the (potentially much larger) components table.
    valid_order_numbers = ComponentSuggestion.pluck(:order_number).to_set

    verified_count   = 0
    unverified_count = 0
    unchanged_count  = 0

    Component.find_each do |component|
      should_be_verified =
        component.order_number.present? && valid_order_numbers.include?(component.order_number)

      if component.order_number_verified == should_be_verified
        unchanged_count += 1
        next
      end

      component.update_column(:order_number_verified, should_be_verified)

      if should_be_verified
        verified_count += 1
      else
        unverified_count += 1
      end
    end

    { verified_count: verified_count, unverified_count: unverified_count, unchanged_count: unchanged_count }
  end
end
