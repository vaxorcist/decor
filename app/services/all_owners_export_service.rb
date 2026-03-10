# decor/app/services/all_owners_export_service.rb
# version 1.0
# Session 24: New service — exports ALL owners' collection data as a single CSV.
#
# Wraps OwnerExportService to produce one combined CSV containing every owner's
# computers and components. An "owner_user_name" column is prepended to the
# standard OwnerExportService headers so each row is traceable to its owner.
#
# This is an admin-only read export. The resulting CSV cannot be directly
# re-imported (AllOwnersExportService::CSV_HEADERS differs from
# OwnerExportService::CSV_HEADERS). To import owner data, use the per-owner
# import on the owner-facing Export/Import page or select a specific owner on
# the admin Imports/Exports page.
#
# CSV format:
#   owner_user_name   — owner's user_name
#   + all columns from OwnerExportService::CSV_HEADERS
#     (record_type, computer_model, computer_order_number, ..., component_description)
#
# Export order: owners alphabetically by user_name; within each owner the
# standard OwnerExportService ordering applies (computers first, then components).
#
# Usage:
#   AllOwnersExportService.export   # → CSV string

require "csv"

class AllOwnersExportService
  # Prepend owner_user_name to the per-owner headers.
  # This constant is public so tests can validate the header row.
  CSV_HEADERS = (["owner_user_name"] + OwnerExportService::CSV_HEADERS).freeze

  # Convenience class method.
  def self.export
    new.to_csv
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS

      # Generate each owner's export, strip its header row, and prepend owner_user_name
      # to every data row. Owners with no records contribute zero rows.
      Owner.order(:user_name).each do |owner|
        per_owner_rows = CSV.parse(OwnerExportService.export(owner), headers: true)

        per_owner_rows.each do |row|
          # Map each standard header to its value in the per-owner row, then prepend name.
          values = OwnerExportService::CSV_HEADERS.map { |header| row[header] }
          csv << ([owner.user_name] + values)
        end
      end
    end
  end
end
