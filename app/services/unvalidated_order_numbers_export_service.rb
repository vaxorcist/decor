# decor/app/services/unvalidated_order_numbers_export_service.rb
# version 1.0
# NEW (Session 65): CSV export of components whose order_number is present but
#   not currently verified (order_number_verified: false). Backs the admin
#   "Download Unvalidated Order Numbers" dropdown action
#   (Admin::ComponentOrderNumbersController#unvalidated).
#
# Purpose: lets the admin review real-world order numbers that owners have
#   typed freely (i.e. NOT accepted from the typeahead / not matched by any
#   current ComponentSuggestion) and decide which ones are worth adding as
#   new ComponentSuggestion rows going forward.
#
# Row shape — confirmed design decision: ONE ROW PER COMPONENT, not
#   deduplicated by order_number value. If five components across different
#   owners share the same unvalidated order_number, all five appear as
#   separate rows. This is deliberate: deduplicating would hide exactly the
#   context (which owner, which component type, which serial number) an
#   admin needs to judge whether a value is a real, recurring order number
#   worth promoting to component_suggestions, or a one-off typo.
#
# Ordering — confirmed design decision: ordered by component (component id,
#   i.e. creation order), NOT grouped or sorted by order_number value.
#
# Exclusion: components with a BLANK order_number are NOT included. An empty
#   order_number is not a "value" to review — it has nothing to offer a new
#   ComponentSuggestion candidate list, and including it would just add noise
#   (every component that has never had an order_number typed in at all).
#
# This is a plain CSV.generate export (no import counterpart) — unlike
#   ComponentSuggestionExportService/ImportService, this list is a read-only
#   review report, not a round-trippable data format.

require "csv"

class UnvalidatedOrderNumbersExportService
  # @return [String] CSV content, one row per unvalidated component
  def self.export
    CSV.generate do |csv|
      csv << %w[order_number component_type owner serial_number description]

      Component
        .where(order_number_verified: false)
        .where.not(order_number: [nil, ""])
        .includes(:component_type, :owner)
        .order(:id)
        .find_each do |component|
          csv << [
            component.order_number,
            component.component_type&.name,
            component.owner&.user_name,
            component.serial_number,
            component.description
          ]
        end
    end
  end
end
