# decor/app/services/all_owners_export_service.rb
# version 1.2
# v1.2 (Storage Locations Session F): Two changes together.
#
#   1. BUG FIX (pre-existing, found while making change 2 below): CSV_HEADERS
#      is derived from OwnerExportService::COMPUTER_SECTION_HEADERS, which
#      Session 70 widened from 8 to 9 columns to add owner_part_number
#      (positioned right after order_number). CSV_HEADERS therefore grew to
#      10 columns automatically at that time — but the to_csv row-building
#      array below was NEVER updated to match; it still pushed only 9 values
#      with no owner_part_number. Every row exported by this file since
#      Session 70 has been silently misaligned: the header row promises
#      owner_part_number in column 5, but the actual value there was
#      serial_number's, shifting every subsequent column by one. Same
#      "single source of truth / touch N places, miss one" shape as the
#      Session 89 components/show.html.erb Owner Part Number display gap
#      (see DECOR_PROJECT.md "Owner Part Number Feature" and
#      RAILS_SPECIFICS.md "Single Source of Truth Refactors"). Fixed here by
#      adding computer.owner_part_number to the row array in the correct
#      position. Found and fixed opportunistically while touching this exact
#      file for the storage_location column below — not a Storage Locations
#      change in itself, flagged to Ulli separately from the storage_location
#      work.
#
#   2. Storage Locations Session F: appended a "storage_location" column
#      (the location's name, or blank when unassigned) as the LAST column —
#      same append-only positioning as OwnerExportService::
#      COMPUTER_SECTION_HEADERS v1.12. Confirmed with the Storage Locations
#      design consultation (DECOR_PROJECT.md "StorageLocation" under Data
#      Model Overview): storage_location is private from OTHER OWNERS and
#      visitors, but explicitly NOT private from admins — this admin-wide
#      export is the one place it's meant to appear outside the owning
#      owner's own views, and Session D's privacy audit (Sessions 86–87)
#      confirmed this file is exempt from that audit's scope.
#      .includes(:storage_location) added to the query to avoid an N+1 (this
#      service already eager-loads every other association it displays).
#
#   With both fixes, CSV_HEADERS now derives cleanly from the full,
#   already-correct COMPUTER_SECTION_HEADERS constant with no manual
#   slicing/re-adding needed — the row-building array below is kept in the
#   same column order as that constant, column for column, so this class of
#   bug can't silently recur the next time OwnerExportService adds a column.
#
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
# CSV format (v1.2):
#   Row 1: CSV_HEADERS — owner_user_name, record_type, model, order_number,
#          owner_part_number, serial_number, condition, run_status, history,
#          barter_status, storage_location (column order matches
#          OwnerExportService::COMPUTER_SECTION_HEADERS exactly, with
#          owner_user_name prepended).
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
  # Prepend owner_user_name to the per-device section headers from
  # OwnerExportService. COMPUTER_SECTION_HEADERS now correctly includes both
  # owner_part_number (Session 70) and storage_location (Session F) in the
  # right order — no manual slicing needed, unlike the ad-hoc approach this
  # would otherwise require. This constant is public so tests can validate
  # the header row.
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
        # includes(:storage_location) added Session F to avoid an N+1 on the new column.
        Computer
          .eager_load(:owner, :computer_model, :computer_condition, :run_status)
          .includes(:storage_location)
          .where(device_type: device_type)
          .order(Arel.sql("owners.user_name ASC, computer_models.name ASC, computers.serial_number ASC"))
          .each do |computer|
            # Column order below MUST match CSV_HEADERS exactly, column for
            # column — CSV_HEADERS is generated from
            # OwnerExportService::COMPUTER_SECTION_HEADERS, so any future
            # column added there needs a matching entry added HERE too (this
            # is exactly the step that was missed for owner_part_number at
            # Session 70 — see the v1.2 bug-fix note above).
            csv << [
              computer.owner.user_name,        # owner attribution column
              record_type_name,                # "computer" or "peripheral"
              computer.computer_model.name,
              computer.order_number,
              computer.owner_part_number,      # v1.2 bug fix — was missing since Session 70
              computer.serial_number,
              computer.computer_condition&.name,
              computer.run_status&.name,
              computer.history,
              computer.barter_status,          # enum string key: "no_barter" / "offered" / "wanted"
              computer.storage_location&.name  # blank when unassigned (Session F)
            ]
          end
      end
    end
  end
end
