# decor/app/services/component_type_export_service.rb
# version 1.0
# Session 24: New service — exports ComponentType reference data as CSV.
#
# Generates a CSV of all ComponentType records, sorted alphabetically by name.
# ComponentType is global reference data (no owner association), so all records
# are exported without any scoping.
#
# CSV format:
#   name — component type name (required; must be unique)
#
# Usage:
#   ComponentTypeExportService.export   # → CSV string

require "csv"

class ComponentTypeExportService
  # CSV header for this format.
  CSV_HEADERS = %w[name].freeze

  # Convenience class method — consistent with other export service interfaces.
  def self.export
    new.to_csv
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS

      # Export all component types, sorted alphabetically.
      ComponentType.order(:name).each do |ct|
        csv << [ct.name]
      end
    end
  end
end
