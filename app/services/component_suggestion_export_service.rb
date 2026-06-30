# decor/app/services/component_suggestion_export_service.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Exports all ComponentSuggestion records as CSV.
# Pattern: identical to ComputerModelExportService.
#
# CSV format:
#   order_number  — unique part number (required)
#   description   — human-readable name (optional, may be blank)
#   category      — informational grouping (optional, may be blank)
#
# Export order: alphabetical by order_number (predictable, diff-friendly).
#
# The exported CSV is the canonical import format for ComponentSuggestionImportService.
# order_number is the stable unique key used for duplicate detection on re-import.
#
# Usage:
#   ComponentSuggestionExportService.export   # → CSV string

require "csv"

class ComponentSuggestionExportService
  # Must match ComponentSuggestionImportService::EXPECTED_HEADERS.
  CSV_HEADERS = %w[order_number description category].freeze

  # Convenience class method — parallel to ComputerModelExportService.export.
  def self.export
    new.to_csv
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS

      # All records regardless of origin, sorted alphabetically by order_number.
      ComponentSuggestion.order(:order_number).each do |suggestion|
        csv << [suggestion.order_number, suggestion.description, suggestion.category]
      end
    end
  end
end
