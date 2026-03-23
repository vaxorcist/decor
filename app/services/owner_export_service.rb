# decor/app/services/owner_export_service.rb
# version 1.3
# Session 37: Three additions:
#
#   1. Ordered export: devices now export in a fixed order — Computers first,
#      then Peripherals, then Appliances — followed by Components.
#      Previously export_computers emitted all device types mixed together sorted
#      by model name. Now replaced by three sequential calls to
#      export_devices_of_type driven by DEVICE_TYPE_EXPORT_ORDER.
#
#   2. Comment header: the first data row of every export is a human-readable
#      comment (record_type starts with '#') containing the owner name and
#      export date. The import parser skips all rows whose record_type starts
#      with '#', so this row is safely ignored on re-import.
#
#   3. Connections section: after all components, if the owner has any connection
#      groups, a sentinel row ('! --- connections ---') is written, followed by
#      connection_group and connection_member rows. The import parser switches to
#      connections-parsing mode when it encounters any row whose record_type starts
#      with '!'. No new CSV headers are needed; existing columns are reused:
#
#        connection_group row:
#          computer_model        → connection_type name (blank if group has no type)
#          computer_order_number → group label (blank if label is nil)
#
#        connection_member row:
#          computer_model         → device model name (for serial disambiguation)
#          computer_serial_number → device serial number
#
# Session 16: device_type support — "appliance" record_type added.
# Session 28: peripheral support — "peripheral" record_type added.
#
# CSV format — one row per record, record_type in the first column:
#
#   "#..."         comment row — skipped by importer (first data row = owner header)
#   "computer"     device_type: 0 (general-purpose computer)
#   "appliance"    device_type: 1 (standalone device: router, server, printer…)
#   "peripheral"   device_type: 2 (I/O device: terminal, storage controller…)
#   "component"    a component attached to or spare from a device
#   "! ---..."     sentinel — starts the connections section
#   "connection_group"   one connection group header
#   "connection_member"  one member (device) of the preceding connection group

require "csv"

class OwnerExportService
  CSV_HEADERS = %w[
    record_type
    computer_model
    computer_order_number
    computer_serial_number
    computer_condition
    computer_run_status
    computer_history
    component_type
    component_order_number
    component_serial_number
    component_condition
    component_description
  ].freeze

  # Defines the order in which device types are written to the CSV.
  # Each entry: [device_type_symbol_for_where_clause, record_type_string_in_csv].
  # Computers first (general purpose), then Peripherals (attached I/O), then
  # Appliances (standalone autonomous devices).
  DEVICE_TYPE_EXPORT_ORDER = [
    [ :computer,   "computer"   ],
    [ :peripheral, "peripheral" ],
    [ :appliance,  "appliance"  ]
  ].freeze

  def initialize(owner)
    @owner = owner
  end

  # Convenience class method — matches the OwnerImportService.process interface.
  def self.export(owner)
    new(owner).to_csv
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS
      write_comment_header(csv)
      DEVICE_TYPE_EXPORT_ORDER.each do |device_type, record_type_name|
        export_devices_of_type(csv, device_type, record_type_name)
      end
      export_components(csv)
      export_connections(csv)
    end
  end

  private

  # ── Comment header ────────────────────────────────────────────────────────

  # Write a comment row as the first data row so humans can identify the file.
  # The importer skips any row whose record_type starts with '#'.
  def write_comment_header(csv)
    csv << ["# Owner: #{@owner.user_name} — exported #{Date.today}"]
  end

  # ── Device rows ───────────────────────────────────────────────────────────

  # Export all devices of a given device_type in model-name + serial-number order.
  # Called three times (by DEVICE_TYPE_EXPORT_ORDER) to produce the ordered block.
  #
  # device_type:      :computer, :peripheral, or :appliance — passed directly to
  #                   .where() which Rails translates via the enum definition.
  # record_type_name: the string written into the record_type column of the CSV.
  def export_devices_of_type(csv, device_type, record_type_name)
    computers = @owner.computers
      .includes(:computer_model, :computer_condition, :run_status)
      .joins(:computer_model)
      .where(device_type: device_type)
      .order(Arel.sql("computer_models.name ASC, computers.serial_number ASC"))

    computers.each do |computer|
      csv << [
        record_type_name,
        computer.computer_model.name,
        computer.order_number,
        computer.serial_number,
        computer.computer_condition&.name,
        computer.run_status&.name,
        computer.history,
        nil, nil, nil, nil, nil  # component columns left blank for device rows
      ]
    end
  end

  # ── Component rows ────────────────────────────────────────────────────────

  def export_components(csv)
    # Sort: attached components before spares; within each group sort by type name.
    components = @owner.components
      .includes(:component_type, :component_condition, computer: :computer_model)
      .joins(:component_type)
      .order(
        Arel.sql("CASE WHEN components.computer_id IS NULL THEN 1 ELSE 0 END ASC"),
        "component_types.name ASC"
      )

    components.each do |component|
      csv << [
        "component",
        nil,                                      # computer_model — blank for components
        nil,                                      # computer_order_number — blank
        component.computer&.serial_number,        # computer_serial_number = FK to parent device
        nil,                                      # computer_condition — blank
        nil,                                      # computer_run_status — blank
        nil,                                      # computer_history — blank
        component.component_type.name,
        component.order_number,
        component.serial_number,
        component.component_condition&.condition, # ComponentCondition stores value in :condition
        component.description
      ]
    end
  end

  # ── Connections section ───────────────────────────────────────────────────

  # Write the optional connections section at the end of the CSV.
  # Only written when the owner has at least one connection group.
  #
  # Structure written:
  #   "! --- connections ---"  — sentinel row, signals start of connections section
  #   For each group:
  #     connection_group row   — connection_type name + label
  #     connection_member rows — one per device in the group (model + serial)
  def export_connections(csv)
    groups = @owner.connection_groups
      .includes(:connection_type, connection_members: { computer: :computer_model })
      .order(:id)

    return if groups.empty?

    # Sentinel: any row whose record_type starts with '!' puts the importer into
    # connections mode. The full string is kept human-readable.
    csv << ["! --- connections ---"]

    groups.each do |group|
      # Group header: reuse computer_model for connection_type name,
      # computer_order_number for the group label. Both may be blank.
      csv << [
        "connection_group",
        group.connection_type&.name,  # computer_model column
        group.label,                  # computer_order_number column
        nil, nil, nil, nil, nil, nil, nil, nil, nil
      ]

      # Member rows: reuse computer_model + computer_serial_number for device
      # identification. Model name is written so the importer can disambiguate
      # when the same serial appears on different models (same owner, diff model).
      group.connection_members.each do |member|
        csv << [
          "connection_member",
          member.computer.computer_model.name,  # computer_model column
          nil,
          member.computer.serial_number,         # computer_serial_number column
          nil, nil, nil, nil, nil, nil, nil, nil
        ]
      end
    end
  end
end
