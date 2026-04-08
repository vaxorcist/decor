# decor/app/services/owner_export_service.rb
# version 1.10
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
# ── CSV format (v1.7+) ───────────────────────────────────────────────────────
#
#   "#..."                   comment row — skipped by importer
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
#   the very first row. The importer handles both formats.

require "csv"

class OwnerExportService
  # ── Per-section column-declaration rows ─────────────────────────────────────
  #
  # Each constant is written immediately after the section sentinel.
  # Only columns actually populated for that record type are listed.
  #
  # v1.8: added barter_status to COMPUTER_SECTION_HEADERS.
  COMPUTER_SECTION_HEADERS = %w[
    record_type model order_number serial_number condition run_status history barter_status
  ].freeze

  # v1.8: added category (component_category enum) and barter_status.
  # v1.9: added installed_on_model — serial numbers are not unique across models;
  #        both model + serial are needed to unambiguously identify the parent computer
  #        on re-import (mirrors SOFTWARE_SECTION_HEADERS which already had both).
  COMPONENT_SECTION_HEADERS = %w[
    record_type installed_on_model installed_on_serial type category order_number serial_number condition description barter_status
  ].freeze

  # Connections section covers two record types that share the same columns
  # with different semantics. The importer distinguishes them via record_type.
  #   connection_group:  connection_type_or_model = connection type name; serial blank.
  #   connection_member: connection_type_or_model = computer model name; label blank.
  # owner_group_id: stable unique key for the group (unique per owner); used by the
  #   importer for duplicate detection. Blank on connection_member rows.
  CONNECTION_SECTION_HEADERS = %w[
    record_type owner_group_id connection_type_or_model label serial_number
  ].freeze

  SOFTWARE_SECTION_HEADERS = %w[
    record_type installed_on_model installed_on_serial name version condition description history barter_status
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

  # ── Device rows (computers + peripherals) ────────────────────────────────────

  # Column layout (COMPUTER_SECTION_HEADERS):
  #   record_type | model | order_number | serial_number | condition |
  #   run_status | history | barter_status
  #
  # barter_status: enum string key — "no_barter", "offered", or "wanted".
  def export_devices_of_type(csv, device_type, sentinel_slug, record_type_name)
    computers = @owner.computers
      .includes(:computer_model, :computer_condition, :run_status)
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
        computer.serial_number,
        computer.computer_condition&.name,
        computer.run_status&.name,
        computer.history,
        computer.barter_status           # enum string key: "no_barter" / "offered" / "wanted"
      ]
    end
  end

  # ── Component rows ────────────────────────────────────────────────────────────

  # Column layout (COMPONENT_SECTION_HEADERS):
  #   record_type | installed_on_model | installed_on_serial | type | category |
  #   order_number | serial_number | condition | description | barter_status
  #
  # installed_on_model and installed_on_serial are both blank for spare components.
  # Both are required together on re-import to unambiguously identify the parent
  # computer — serial_number alone is not unique across models for a given owner.
  def export_components(csv)
    components = @owner.components
      .includes(:component_type, :component_condition, computer: :computer_model)
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
        component.serial_number,
        component.component_condition&.condition,
        component.description,
        component.barter_status                   # enum string key
      ]
    end
  end

  # ── Connections section ───────────────────────────────────────────────────────

  # Column layout (CONNECTION_SECTION_HEADERS):
  #   record_type | owner_group_id | connection_type_or_model | label | serial_number
  # owner_group_id is the stable unique key for duplicate detection on re-import.
  # It is present on connection_group rows and blank on connection_member rows.
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
  #   condition | description | history | barter_status
  #
  # installed_on_model and installed_on_serial are blank when computer_id is nil.
  # eager_load used so the LEFT OUTER JOIN is present for multi-table ORDER BY.
  def export_software_items(csv)
    items = @owner.software_items
      .eager_load(:software_name, :software_condition, computer: :computer_model)
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
        item.barter_status
      ]
    end
  end
end
