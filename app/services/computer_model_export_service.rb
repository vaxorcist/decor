# decor/app/services/computer_model_export_service.rb
# version 1.0
# Session 24: New service — exports ComputerModel reference data as CSV.
#
# Generates a CSV of all ComputerModel records for a given device_type.
# Computer models (device_type: 0) and appliance models (device_type: 1) share
# the same AR model but are exported separately so each CSV file is self-contained
# and can be re-imported via ComputerModelImportService with the correct device_type.
#
# CSV format:
#   name — model name (required; must be unique across all ComputerModel records)
#
# The device_type is NOT included as a CSV column because it is determined by the
# UI selector (Computer Models vs Appliance Models) when importing. This keeps
# the format minimal and consistent with how ComponentTypeExportService works.
#
# Export order: alphabetical by name.
#
# Usage:
#   ComputerModelExportService.export(device_type: :computer)   # → CSV string
#   ComputerModelExportService.export(device_type: :appliance)  # → CSV string

require "csv"

class ComputerModelExportService
  # CSV header for this format.
  CSV_HEADERS = %w[name].freeze

  # Convenience class method — parallel to OwnerExportService.export(owner).
  def self.export(device_type: :computer)
    new(device_type: device_type).to_csv
  end

  def initialize(device_type: :computer)
    @device_type = device_type
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS

      # Scope to the requested device_type and sort alphabetically.
      # All ComputerModel records regardless of owner are included — this is
      # reference/lookup data, not owner-scoped data.
      ComputerModel.where(device_type: @device_type).order(:name).each do |model|
        csv << [model.name]
      end
    end
  end
end
