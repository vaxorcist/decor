# decor/app/controllers/admin/component_order_numbers_controller.rb
# version 1.0
# NEW (Session 65): Two bulk-maintenance actions for Component#order_number,
#   backing the admin Components dropdown items:
#     "Re-validate Order Numbers"            → #revalidate
#     "Download Unvalidated Order Numbers"   → #unvalidated
#
# Not a resourceful CRUD controller — deliberately has no index/show/new/etc.
# Both actions operate across ALL Component records regardless of owner; this
# is reference-data maintenance (syncing against component_suggestions), not
# an owner-scoped operation — same scope pattern as Admin::ComponentSuggestionsController.
#
# Auth: inherits require_admin from Admin::BaseController, same as every other
# admin:: controller in this project.

module Admin
  class ComponentOrderNumbersController < BaseController
    # POST /admin/component_order_numbers/revalidate
    #
    # Re-syncs order_number_verified for every Component against the current
    # component_suggestions table. Confirmed design decision: applies
    # immediately, no preview step — this is treated as a safe, idempotent
    # data-integrity sync (running it twice in a row with no data changes in
    # between produces zero further changes).
    #
    # Rationale for "no preview": the operation is fully deterministic and
    # reversible in the sense that running it again always converges to the
    # same correct state; there is no destructive or one-way side effect that
    # would justify a confirmation screen beyond the browser-level
    # turbo_confirm dialog already present on the dropdown link.
    def revalidate
      result = ComponentOrderNumberRevalidationService.call

      flash[:notice] =
        "Re-validated order numbers: #{result[:verified_count]} component(s) " \
        "marked verified, #{result[:unverified_count]} component(s) marked " \
        "unverified (#{result[:unchanged_count]} unchanged)."

      redirect_to admin_component_suggestions_path
    end

    # GET /admin/component_order_numbers/unvalidated
    #
    # Streams a CSV of components whose order_number is present but
    # order_number_verified is currently false — i.e. order numbers owners
    # typed freely that have never matched (or no longer match) a
    # ComponentSuggestion. One row per component (confirmed design decision —
    # NOT deduplicated by order_number value), so the admin can see exactly
    # which owners/components are carrying each unvalidated value before
    # deciding whether to add it as a new ComponentSuggestion.
    def unvalidated
      csv = UnvalidatedOrderNumbersExportService.export

      send_data csv,
        filename:    "unvalidated_order_numbers_#{Date.today}.csv",
        type:        "text/csv; charset=utf-8",
        disposition: "attachment"
    end
  end
end
