# decor/app/services/owner_export_service.rb
# version 1.12
# v1.12 (Storage Locations Session F): Export support for Storage Locations.
#   Added a new "! --- storage_locations ---" section, written FIRST (before
#   computers/peripherals) so the corresponding import can create locations
#   before anything references them by name — mirrors the dependency
#   ordering documented in DECOR_PROJECT.md "Storage Locations Feature —
#   Session Plan," Session F. Natural key: name (scoped to the owner the
#   whole file already belongs to) — no synthetic ID needed, per
#   PROGRAMMING_GENERAL.md "Export / Import — Always Include a Stable
#   Unique Key."
#
#   Added a "storage_location" column (the location's name, or blank when
#   unassigned) as the LAST column on COMPUTER_SECTION_HEADERS,
#   COMPONENT_SECTION_HEADERS, and SOFTWARE_SECTION_HEADERS. Appended at
#   the end (not interleaved with existing columns) so that any importer
#   or external tool still reading columns positionally against an older
#   header list is unaffected — the new column simply reads as absent.
#   (This codebase's own importer reads by name via col(), so position
#   doesn't matter there, but the append-only choice costs nothing and
#   avoids disturbing the CONNECTION_SECTION_HEADERS-adjacent column
#   grouping story documented in prior version-header comments.)
#
#   CONNECTION_SECTION_HEADERS unchanged — connections reference computers
#   by model+serial only, same reasoning already applied to
#   owner_part_number in v1.11.
#
# v1.11 (Session 70): Owner Part Number feature.
#   Added "owner_part_number" to COMPUTER_SECTION_HEADERS (positioned right
#   after order_number, before serial_number — groups the two DEC-database
#   identifier columns with the new owner-supplied one) and to
#   COMPONENT_SECTION_HEADERS (same relative position). Both
#   export_devices_of_type and export_components updated to write the new
#   column. CONNECTION_SECTION_HEADERS unchanged — connections reference
#   computers by model+serial only and don't need this field.
#   computer_model_export_service.rb intentionally NOT touched — confirmed
#   with Ulli (Session 70) that it exports ComputerModel reference/catalog
#   data only (model names), which has no relationship to per-instance
#   owner_part_number values.
#
# v1.10 (Session 49 — Session G): Added owner_group_id to CONNECTION_SECTION_HEADERS.
#   The member-set duplicate check used by the importer (v1.10) is fragile — adding a
#   new port to an existing connection changes the set, causing the group to be saved
#   again on re-import. Fix: export the stable unique key (owner_group_id, unique per
#   owner) so the importer can do a direct exists? check instead.
#   owner_group_id is written on connection_group rows; blank on connection_member rows.
#   Rule: every exported record type must carry a stable unique key for duplicate detection.
#
# v1.9 (Session 49 — Session G): Added installed_on_model to COMPONENT_SECTION_HEADERS.
#   Fix: export installed_on_model alongside installed_on_serial, mirroring the
#   SOFTWARE_SECTION_HEADERS pattern that already included both columns.
#
# v1.8 (Session 48): Added missing columns.
#   COMPUTER_SECTION_HEADERS: added barter_status (was exported for computers
#     and peripherals but missing from both the header row and the data rows).
#   COMPONENT_SECTION_HEADERS: added category (component_category enum:
#     integral/peripheral, prefix: true) and barter_status (enum: no_barter/
#     offered/wanted, prefix: true). Both were present on the model but absent
#     from the export.
#
# v1.7 (Session 48): Per-section column headers — format redesign.
#   Removed global CSV_HEADERS row. Each section now starts with its own
#   sentinel ("! --- section ---") followed by a section-specific
#   column-declaration row. Variable column counts per section.
#
# v1.6 (Session 48): Bug fix — software_item rows now populate installed_on_model.
# v1.5 (Session 48): Software feature Session F — software items export.
# v1.4 (Session 41): Appliances → Peripherals merger Phase 4.
# v1.3 (Session 37): Ordered export; comment header; connections section.
# v1.2 (Session 28): Peripheral record_type added.
# v1.1 (Session 16): Appliance record_type added.
#
# ── CSV format (v1.12+) ──────────────────────────────────────────────────────
#
#   "#..."                       comment row — skipped by importer
#
#   "! --- storage_locations ---"  section sentinel (Storage Locations Session F)
#   record_type,name              column-declaration row
#   "storage_location",...        data rows
#
#   "! --- computers ---"    section sentinel
#   record_type,model,...    column-declaration row (section-specific)
#   "computer",...           data rows
#
#   "! --- peripherals ---"  section sentinel
#   record_type,model,...    column-declaration row
#   "peripheral",...         data rows
#
#   "! --- components ---"   section sentinel
#   record_type,...          column-declaration row
#   "component",...          data rows
#
#   "! --- connections ---"  section sentinel
#   record_type,...          column-declaration row
#   "connection_group",...   data rows
#   "connection_member",...  data rows (immediately follow their parent group)
#
#   "! --- software ---"     section sentinel
#   record_type,...          column-declaration row
#   "software_item",...      data rows
#
#   Empty sections are silently skipped — no sentinel written.
#
#   Legacy note: CSVs exported before v1.7 have a global 18-column header as
#   the very first row. CSVs exported before v1.11 have no owner_part_number
#   column at all. CSVs exported before v1.12 have no storage_locations
#   section and no storage_location column at all. The importer handles all
#   of these — a missing owner_part_number column simply results in the
#   model's before_validation default ("-") being applied on import (see
#   owner_import_service.rb v1.12), and a missing storage_location column
#   simply results in no location being assigned (see owner_import_service.rb
#   v1.13).

require "csv"

class OwnerExportService
  # ── Per-section column-declaration rows ─────────────────────────────────────
  #
  # Each constant is written immediately after the section sentinel.
  # Only columns actually populated for that record type are listed.
  #
  # Storage Locations Session F: new section, natural key is just "name" —
  # the whole file already belongs to one owner, so no owner reference is
  # needed within the row itself.
  STORAGE_LOCATION_SECTION_HEADERS = %w[
    record_type name
  ].freeze

  # v1.12: added storage_location as the LAST column (see class-header
  # comment above for why it's appended rather than interleaved).
  # v1.11: added owner_part_number, positioned right after order_number.
  COMPUTER_SECTION_HEADERS = %w[
    record_type model order_number owner_part_number serial_number condition run_status history barter_status storage_location
  ].freeze

  # v1.12: added storage_location as the LAST column.
  # v1.11: added owner_part_number, positioned right after order_number
  # (same relative position as COMPUTER_SECTION_HEADERS above).
  COMPONENT_SECTION_HEADERS = %w[
    record_type installed_on_model installed_on_serial type category order_number owner_part_number serial_number condition description barter_status storage_location
  ].freeze

  # Connections section covers two record types that share the same columns
  # with different semantics. The importer distinguishes them via record_type.
  #   connection_group:  connection_type_or_model = connection type name; serial blank.
  #   connection_member: connection_type_or_model = computer model name; label blank.
  # owner_group_id: stable unique key for the group (unique per owner); used by the
  #   importer for duplicate detection. Blank on connection_member rows.
  # Not touched Session 70 or Storage Locations Session F — connections identify
  # computers by model+serial only, and a connection itself has no physical
  # storage location independent of its member computers.
  CONNECTION_SECTION_HEADERS = %w[
    record_type owner_group_id connection_type_or_model label serial_number
  ].freeze

  # v1.12: added storage_location as the LAST column.
  SOFTWARE_SECTION_HEADERS = %w[
    record_type installed_on_model installed_on_serial name version condition description history barter_status storage_location
  ].freeze

  # Controls the order in which device types are exported.
  # Each triple: [ device_type_symbol, sentinel_slug, record_type_name ]
  DEVICE_TYPE_EXPORT_ORDER = [
    [ :computer,   "computers",   "computer"   ],
    [ :peripheral, "peripherals", "peripheral" ]
  ].freeze

  def initialize(owner)
    @owner = owner
  end

  def self.export(owner)
    new(owner).to_csv
  end

  def to_csv
    # force_quotes: true wraps every cell in double-quotes for unambiguous parsing.
    # No global headers row — each section writes its own column-declaration row.
    CSV.generate(force_quotes: true) do |csv|
      write_comment_header(csv)
      # Storage Locations Session F: written FIRST, before any section that
      # can reference a location by name — mirrors the import-side dependency
      # ordering (owner_import_service.rb processes this section before
      # computers/components/software for the same reason).
      export_storage_locations(csv)
      DEVICE_TYPE_EXPORT_ORDER.each do |device_type, sentinel_slug, record_type_name|
        export_devices_of_type(csv, device_type, sentinel_slug, record_type_name)
      end
      export_components(csv)
      export_connections(csv)
      export_software_items(csv)
    end
  end

  private

  # ── Comment header ────────────────────────────────────────────────────────────

  # First row of the file. Starts with "#" so importer can detect and skip it.
  def write_comment_header(csv)
    csv << ["# Owner: #{@owner.user_name} — exported #{Date.today}"]
  end

  # ── Storage Locations section (Storage Locations Session F) ─────────────────

  # Column layout (STORAGE_LOCATION_SECTION_HEADERS):
  #   record_type | name
  #
  # Ordered alphabetically (case-insensitive) by name for readability — no
  # functional requirement drives the order, since the importer's duplicate
  # check is a plain name lookup regardless of row order.
  def export_storage_locations(csv)
    locations = @owner.storage_locations.order(Arel.sql("LOWER(name) ASC"))

    return if locations.empty?

    csv << ["! --- storage_locations ---"]
    csv << STORAGE_LOCATION_SECTION_HEADERS

    locations.each do |location|
      csv << [
        "storage_location",
        location.name
      ]
    end
  end

  # ── Device rows (computers + peripherals) ────────────────────────────────────

  # Column layout (COMPUTER_SECTION_HEADERS):
  #   record_type | model | order_number | owner_part_number | serial_number |
  #   condition | run_status | history | barter_status | storage_location
  #
  # barter_status: enum string key — "no_barter", "offered", or "wanted".
  # storage_location: the location's name, or blank when unassigned (Session F).
  def export_devices_of_type(csv, device_type, sentinel_slug, record_type_name)
    computers = @owner.computers
      .includes(:computer_model, :computer_condition, :run_status, :storage_location)
      .joins(:computer_model)
      .where(device_type: device_type)
      .order(Arel.sql("computer_models.name ASC, computers.serial_number ASC"))

    return if computers.empty?

    csv << ["! --- #{sentinel_slug} ---"]
    csv << COMPUTER_SECTION_HEADERS

    computers.each do |computer|
      csv << [
        record_type_name,
        computer.computer_model.name,
        computer.order_number,
        computer.owner_part_number,
        computer.serial_number,
        computer.computer_condition&.name,
        computer.run_status&.name,
        computer.history,
        computer.barter_status,          # enum string key: "no_barter" / "offered" / "wanted"
        computer.storage_location&.name  # blank when unassigned (Session F)
      ]
    end
  end

  # ── Component rows ────────────────────────────────────────────────────────────

  # Column layout (COMPONENT_SECTION_HEADERS):
  #   record_type | installed_on_model | installed_on_serial | type | category |
  #   order_number | owner_part_number | serial_number | condition | description |
  #   barter_status | storage_location
  #
  # installed_on_model and installed_on_serial are both blank for spare components.
  # Both are required together on re-import to unambiguously identify the parent
  # computer — serial_number alone is not unique across models for a given owner.
  # storage_location: the location's name, or blank when unassigned (Session F).
  def export_components(csv)
    components = @owner.components
      .includes(:component_type, :component_condition, :storage_location, computer: :computer_model)
      .joins(:component_type)
      .order(
        Arel.sql("CASE WHEN components.computer_id IS NULL THEN 1 ELSE 0 END ASC"),
        "component_types.name ASC"
      )

    return if components.empty?

    csv << ["! --- components ---"]
    csv << COMPONENT_SECTION_HEADERS

    components.each do |component|
      csv << [
        "component",
        component.computer&.computer_model&.name,  # blank for spares; needed with serial to unambiguously identify parent
        component.computer&.serial_number,         # blank for spares
        component.component_type.name,
        component.component_category,             # "integral" or "peripheral"
        component.order_number,
        component.owner_part_number,
        component.serial_number,
        component.component_condition&.condition,
        component.description,
        component.barter_status,                   # enum string key
        component.storage_location&.name            # blank when unassigned (Session F)
      ]
    end
  end

  # ── Connections section ───────────────────────────────────────────────────────

  # Column layout (CONNECTION_SECTION_HEADERS):
  #   record_type | owner_group_id | connection_type_or_model | label | serial_number
  # owner_group_id is the stable unique key for duplicate detection on re-import.
  # It is present on connection_group rows and blank on connection_member rows.
  # No storage_location column here — a connection has no physical location of
  # its own independent of its member computers (Session F confirmed this is
  # out of scope for connections).
  def export_connections(csv)
    groups = @owner.connection_groups
      .includes(:connection_type, connection_members: { computer: :computer_model })
      .order(:id)

    return if groups.empty?

    csv << ["! --- connections ---"]
    csv << CONNECTION_SECTION_HEADERS

    groups.each do |group|
      csv << [
        "connection_group",
        group.owner_group_id,
        group.connection_type&.name,
        group.label,
        nil
      ]

      group.connection_members.each do |member|
        csv << [
          "connection_member",
          nil,
          member.computer.computer_model.name,
          nil,
          member.computer.serial_number
        ]
      end
    end
  end

  # ── Software section ──────────────────────────────────────────────────────────

  # Column layout (SOFTWARE_SECTION_HEADERS):
  #   record_type | installed_on_model | installed_on_serial | name | version |
  #   condition | description | history | barter_status | storage_location
  #
  # installed_on_model and installed_on_serial are blank when computer_id is nil.
  # eager_load used so the LEFT OUTER JOIN is present for multi-table ORDER BY.
  # storage_location: the location's name, or blank when unassigned (Session F).
  def export_software_items(csv)
    items = @owner.software_items
      .eager_load(:software_name, :software_condition, :storage_location, computer: :computer_model)
      .order(Arel.sql("software_names.name ASC, software_items.version ASC NULLS LAST"))

    return if items.empty?

    csv << ["! --- software ---"]
    csv << SOFTWARE_SECTION_HEADERS

    items.each do |item|
      csv << [
        "software_item",
        item.computer&.computer_model&.name,
        item.computer&.serial_number,
        item.software_name.name,
        item.version,
        item.software_condition&.name,
        item.description,
        item.history,
        item.barter_status,
        item.storage_location&.name  # blank when unassigned (Session F)
      ]
    end
  end
end
