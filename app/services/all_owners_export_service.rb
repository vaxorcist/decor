# decor/app/services/all_owners_export_service.rb
# version 1.1
# v1.1 (Session 50): Removed dependency on OwnerExportService::CSV_HEADERS.
#   OwnerExportService v1.7 (Session 48) replaced the global CSV_HEADERS constant
#   with per-section sentinels and section-specific column-declaration rows.
#   AllOwnersExportService was never updated and crashed at class-load time with
#   NameError: uninitialized constant OwnerExportService::CSV_HEADERS.
#
#   Fix: define own CSV_HEADERS based on COMPUTER_SECTION_HEADERS (which still
#   exists), and rewrite to_csv to query the database directly rather than
#   wrapping OwnerExportService.export(). The old approach parsed the per-owner
#   CSV string back with CSV.parse(headers: true) — no longer valid because the
#   new format starts with a comment row and uses per-section column declarations.
#
#   The output format is unchanged from the user's perspective: a flat CSV with
#   owner_user_name prepended to each device row. Owners with no records
#   contribute zero rows.
#
# v1.0 (Session 24): New service — exports ALL owners' collection data as a
#   single CSV. Wraps OwnerExportService to produce one combined CSV containing
#   every owner's computers and components.
#
# CSV format (v1.1):
#   Row 1: CSV_HEADERS (global header, one row)
#   Rows 2+: one row per device (computer or peripheral), ordered by
#             owner user_name ASC, then model name ASC, then serial_number ASC.
#
# This is an admin-only read export. The resulting CSV cannot be directly
# re-imported (it lacks the per-section sentinel format used by OwnerImportService).
# To import owner data, use the per-owner import on the owner-facing Export/Import
# page or select a specific owner on the admin Imports/Exports page.
#
# Usage:
#   AllOwnersExportService.export   # → CSV string

require "csv"

class AllOwnersExportService
  # Prepend owner_user_name to the per-device section headers from OwnerExportService.
  # COMPUTER_SECTION_HEADERS covers both computers and peripherals (same columns).
  # This constant is public so tests can validate the header row.
  CSV_HEADERS = (["owner_user_name"] + OwnerExportService::COMPUTER_SECTION_HEADERS).freeze

  # Convenience class method.
  def self.export
    new.to_csv
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS

      # Iterate device types in the same order as OwnerExportService (computers first,
      # then peripherals), using DEVICE_TYPE_EXPORT_ORDER so any future reordering
      # in OwnerExportService is automatically reflected here.
      OwnerExportService::DEVICE_TYPE_EXPORT_ORDER.each do |device_type, _sentinel_slug, record_type_name|
        # Query all owners' devices of this type in one pass, ordered for readability.
        # eager_load used for multi-table ORDER BY (produces LEFT OUTER JOIN).
        Computer
          .eager_load(:owner, :computer_model, :computer_condition, :run_status)
          .where(device_type: device_type)
          .order(Arel.sql("owners.user_name ASC, computer_models.name ASC, computers.serial_number ASC"))
          .each do |computer|
            csv << [
              computer.owner.user_name,     # owner attribution column
              record_type_name,             # "computer" or "peripheral"
              computer.computer_model.name,
              computer.order_number,
              computer.serial_number,
              computer.computer_condition&.name,
              computer.run_status&.name,
              computer.history,
              computer.barter_status        # enum string key: "no_barter" / "offered" / "wanted"
            ]
          end
      end
    end
  end
end
