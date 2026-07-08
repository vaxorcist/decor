# decor/app/services/manual_component_suggestions_export_service.rb
# version 1.1
# Session 67 (fix): read_attribute(:manual) does NOT return the raw DB value
# for an enum-backed column, as v1.0 incorrectly assumed. Rails' `enum`
# attaches a custom type to the attribute at the schema level, so
# read_attribute still goes through that type's cast — it returns the same
# mapped string ("added"/"modified") as the plain `suggestion.manual` accessor.
# The correct way to read the underlying raw stored value ("a"/"m") is the
# auto-generated `_before_type_cast` method, which explicitly bypasses the
# attribute's type-casting layer. Confirmed by test failure: the CSV was
# showing "added"/"modified" instead of "a"/"m" in the manual column.
#
# Session 67: Phase 4 item 2 — "Download Manual Changes" admin feature.
#
# Exports every ComponentSuggestion row that has been touched by hand via the
# admin form — manual: "a" (added) or manual: "m" (modified), both included
# in one download, confirmed Session 66. Rows with manual: nil (untouched
# bulk-import records) are excluded.
#
# WHY THIS SERVICE EXISTS: ComponentSuggestionImportService v2.0 deletes ALL
# component_suggestions rows unconditionally on every re-import, with no
# preservation logic of any kind (confirmed design — see that service's file
# header and SESSION_HANDOVER.md "Session 66 Summary" item 3a). This export
# is the admin's ONLY way to keep a record of manual work before running a
# re-import — it must be downloaded proactively, before triggering the
# import; nothing in the import path re-applies it automatically.
#
# CSV format: same three columns as ComponentSuggestionExportService, plus
# the manual flag itself (so the raw "a"/"m" value is preserved in the
# download, in case an admin wants to inspect or manually re-key rows from
# it after a re-import):
#   order_number, description, category, manual
#
# Export order: alphabetical by order_number, matching the existing full
# export's ordering convention (ComponentSuggestionExportService).
#
# Usage:
#   ManualComponentSuggestionsExportService.export   # → CSV string

require "csv"

class ManualComponentSuggestionsExportService
  CSV_HEADERS = %w[order_number description category manual].freeze

  # Convenience class method — parallel to ComponentSuggestionExportService.export.
  def self.export
    new.to_csv
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS

      # where.not(manual: nil) — both "a" and "m" rows, together, one download
      # (confirmed Session 66: "both together, one download").
      ComponentSuggestion.where.not(manual: nil).order(:order_number).each do |suggestion|
        # manual_before_type_cast (NOT read_attribute — see file header fix
        # note) returns the raw one-character DB value ("a" / "m"), bypassing
        # the enum's type-casting layer that suggestion.manual / read_attribute
        # both go through. Kept identical to the raw DB value so this file
        # could, in principle, be reloaded/inspected alongside the raw schema
        # without needing the enum mapping in mind.
        csv << [
          suggestion.order_number,
          suggestion.description,
          suggestion.category,
          suggestion.manual_before_type_cast
        ]
      end
    end
  end
end
