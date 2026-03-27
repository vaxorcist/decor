# decor/app/services/owner_import_service.rb
# version 1.5
# v1.5 (Session 41): Appliances → Peripherals merger Phase 4.
#   Added backward-compat mapping: CSV record_type "appliance" is now silently
#   treated as "peripheral" on import. This allows CSVs exported before the
#   Session 41 merger to remain importable without modification.
#   The imported record's device_type is :peripheral (device_type=2); the legacy
#   "appliance" value (device_type=1) is no longer used.
#   @appliance_count removed from result hash — appliance rows now increment
#   @peripheral_count. Callers should use :peripheral_count.
# v1.4 (Session 37): Comment rows; sentinel detection; pass 3 connections.
# v1.3 (Session 28): Separate per-device-type counters; peripheral record_type.
# v1.2 (Session 28): Peripheral record_type.
# v1.1 (Session 16): Appliance record_type (now replaced by backward-compat mapping).

require "csv"

class OwnerImportService
  EXPECTED_HEADERS = %w[
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

  MAX_FILE_SIZE = 10.megabytes

  def initialize(owner, file)
    @owner            = owner
    @file             = file
    @errors           = []
    @computer_count   = 0
    @peripheral_count = 0
    @component_count  = 0
    # Counts successfully saved connection groups (not members).
    @connection_group_count = 0
  end

  def self.process(owner, file)
    new(owner, file).process
  end

  def process
    validate_file!
    return error_result if @errors.any?

    begin
      ActiveRecord::Base.transaction do
        process_csv
        raise ActiveRecord::Rollback if @errors.any?
      end

      return error_result if @errors.any?

      {
        success:                true,
        computer_count:         @computer_count,
        peripheral_count:       @peripheral_count,
        component_count:        @component_count,
        connection_group_count: @connection_group_count
      }
    rescue ActiveRecord::Rollback
      error_result
    rescue => e
      { success: false, error: "Unexpected error: #{e.message}" }
    end
  end

  private

  # ── File validation ────────────────────────────────────────────────────────

  def validate_file!
    if @file.nil?
      @errors << "No file provided"
      return
    end
    if @file.size > MAX_FILE_SIZE
      @errors << "File exceeds #{MAX_FILE_SIZE / 1.megabyte}MB limit"
      return
    end
    unless @file.content_type == "text/csv" || @file.original_filename.end_with?(".csv")
      @errors << "File must be a CSV (.csv)"
    end
  end

  # ── CSV parsing & multi-pass dispatch ─────────────────────────────────────

  def process_csv
    csv_data = CSV.read(@file.path, headers: true)

    validate_headers!(csv_data.headers)
    return if @errors.any?

    computer_rows       = []
    component_rows      = []
    connection_rows     = []
    in_connections_mode = false

    csv_data.each_with_index do |row, index|
      row_num     = index + 2
      record_type = row["record_type"]&.strip

      next if record_type&.start_with?("#")

      if record_type&.start_with?("!")
        in_connections_mode = true
        next
      end

      if in_connections_mode
        case record_type&.downcase
        when "connection_group"  then connection_rows << [row, row_num, :group]
        when "connection_member" then connection_rows << [row, row_num, :member]
        else
          unless row.fields.all?(&:nil?)
            @errors << "Row #{row_num}: unknown record_type '#{record_type}' " \
                       "in connections section (expected 'connection_group' or 'connection_member')"
          end
        end
      else
        case record_type&.downcase
        when "computer"   then computer_rows  << [row, row_num, :computer]
        when "peripheral" then computer_rows  << [row, row_num, :peripheral]
        # Backward compatibility: CSVs exported before the Session 41 appliance→peripheral
        # merger may contain "appliance" rows. Map them to :peripheral on import so that
        # old exports remain importable without modification.
        when "appliance"  then computer_rows  << [row, row_num, :peripheral]
        when "component"  then component_rows << [row, row_num]
        else
          unless row.fields.all?(&:nil?)
            @errors << "Row #{row_num}: unknown record_type '#{record_type}' " \
                       "(valid: 'computer', 'peripheral', 'component'; " \
                       "'appliance' is accepted as a legacy alias for 'peripheral'; " \
                       "put 'connection_group'/'connection_member' rows after " \
                       "'! --- connections ---')"
          end
        end
      end
    end

    computer_rows.each { |row, row_num, device_type| process_computer_row(row, row_num, device_type) }
    component_rows.each { |row, row_num| process_component_row(row, row_num) }
    process_connection_rows(connection_rows)
  end

  def validate_headers!(headers)
    return if headers.blank?

    missing = EXPECTED_HEADERS - headers.map(&:to_s)
    if missing.any?
      @errors << "Missing required CSV columns: #{missing.join(', ')}"
    end
  end

  # ── Computer row processing ────────────────────────────────────────────────

  # Processes a computer or peripheral row (including legacy appliance rows
  # remapped to :peripheral by the dispatch above).
  def process_computer_row(row, row_num, device_type = :computer)
    serial_number = row["computer_serial_number"]&.strip
    model_name    = row["computer_model"]&.strip

    if serial_number.blank?
      @errors << "Row #{row_num}: computer_serial_number is required for computer records"
      return
    end
    if model_name.blank?
      @errors << "Row #{row_num}: computer_model is required for computer records"
      return
    end

    model = ComputerModel.find_by(name: model_name)
    if model.nil?
      @errors << "Row #{row_num}: Computer model '#{model_name}' not found. " \
                 "Ask an admin to create it first."
      return
    end

    return if @owner.computers.exists?(computer_model: model, serial_number: serial_number)

    condition = resolve_computer_condition(row["computer_condition"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    run_status = resolve_run_status(row["computer_run_status"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    computer = @owner.computers.build(
      serial_number:      serial_number,
      order_number:       row["computer_order_number"]&.strip.presence,
      history:            row["computer_history"]&.strip.presence,
      computer_model:     model,
      computer_condition: condition,
      run_status:         run_status,
      device_type:        device_type
    )

    if computer.save
      case device_type
      when :peripheral then @peripheral_count += 1
      else                  @computer_count   += 1
      end
    else
      @errors << "Row #{row_num}: #{computer.errors.full_messages.join(', ')}"
    end
  end

  # ── Component row processing ───────────────────────────────────────────────

  def process_component_row(row, row_num)
    type_name = row["component_type"]&.strip

    if type_name.blank?
      @errors << "Row #{row_num}: component_type is required for component records"
      return
    end

    component_type = ComponentType.find_by(name: type_name)
    if component_type.nil?
      @errors << "Row #{row_num}: Component type '#{type_name}' not found. " \
                 "Ask an admin to create it first."
      return
    end

    serial_number = row["component_serial_number"]&.strip.presence
    if serial_number && @owner.components.exists?(component_type: component_type,
                                                   serial_number: serial_number)
      return
    end

    condition = resolve_component_condition(row["component_condition"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    computer_serial = row["computer_serial_number"]&.strip.presence
    computer = computer_serial ? @owner.computers.find_by(serial_number: computer_serial) : nil

    component = @owner.components.build(
      component_type:      component_type,
      component_condition: condition,
      computer:            computer,
      serial_number:       serial_number,
      order_number:        row["component_order_number"]&.strip.presence,
      description:         row["component_description"]&.strip.presence
    )

    if component.save
      @component_count += 1
    else
      @errors << "Row #{row_num}: #{component.errors.full_messages.join(', ')}"
    end
  end

  # ── Connection row processing (pass 3) ────────────────────────────────────

  def process_connection_rows(connection_rows)
    return if connection_rows.empty?

    groups_data = []
    current     = nil

    connection_rows.each do |row, row_num, type|
      if type == :group
        groups_data << current if current
        current = { group_row: [row, row_num], member_rows: [] }
      elsif type == :member
        if current.nil?
          @errors << "Row #{row_num}: connection_member row appears before " \
                     "any connection_group row"
          return
        end
        current[:member_rows] << [row, row_num]
      end
    end
    groups_data << current if current

    groups_data.each do |group_data|
      process_one_connection_group(group_data[:group_row], group_data[:member_rows])
    end
  end

  def process_one_connection_group(group_row_data, member_rows_data)
    row, row_num = group_row_data

    type_name = row["computer_model"]&.strip.presence
    connection_type = nil
    if type_name.present?
      connection_type = ConnectionType.find_by(name: type_name)
      if connection_type.nil?
        @errors << "Row #{row_num}: Connection type '#{type_name}' not found. " \
                   "Ask an admin to create it first."
        return
      end
    end

    label = row["computer_order_number"]&.strip.presence

    group = @owner.connection_groups.build(
      connection_type: connection_type,
      label:           label
    )

    member_rows_data.each do |member_row, member_row_num|
      computer = find_member_computer(member_row, member_row_num)
      return if @errors.last&.start_with?("Row #{member_row_num}")
      group.connection_members.build(computer: computer)
    end

    unless group.save
      @errors << "Row #{row_num}: #{group.errors.full_messages.join(', ')}"
      return
    end

    @connection_group_count += 1
  end

  def find_member_computer(member_row, row_num)
    model_name = member_row["computer_model"]&.strip.presence
    serial     = member_row["computer_serial_number"]&.strip

    if serial.blank?
      @errors << "Row #{row_num}: connection_member requires computer_serial_number"
      return nil
    end

    if model_name.present?
      computer = @owner.computers
        .joins(:computer_model)
        .find_by(computer_models: { name: model_name }, serial_number: serial)
      if computer.nil?
        @errors << "Row #{row_num}: Computer '#{model_name} — #{serial}' " \
                   "not found for this owner"
      end
      computer
    else
      matches = @owner.computers.where(serial_number: serial).to_a
      case matches.size
      when 1 then matches.first
      when 0
        @errors << "Row #{row_num}: Computer with serial '#{serial}' " \
                   "not found for this owner"
        nil
      else
        @errors << "Row #{row_num}: Serial '#{serial}' matches #{matches.size} devices. " \
                   "Add the model name in the computer_model column to disambiguate."
        nil
      end
    end
  end

  # ── Lookup helpers ─────────────────────────────────────────────────────────

  def resolve_computer_condition(name, row_num)
    return nil if name.blank?

    record = ComputerCondition.find_by(name: name)
    if record.nil?
      @errors << "Row #{row_num}: Computer condition '#{name}' not found. " \
                 "Ask an admin to create it first."
    end
    record
  end

  def resolve_run_status(name, row_num)
    return nil if name.blank?

    record = RunStatus.find_by(name: name)
    if record.nil?
      @errors << "Row #{row_num}: Run status '#{name}' not found. " \
                 "Ask an admin to create it first."
    end
    record
  end

  def resolve_component_condition(value, row_num)
    return nil if value.blank?

    record = ComponentCondition.find_by(condition: value)
    if record.nil?
      @errors << "Row #{row_num}: Component condition '#{value}' not found. " \
                 "Ask an admin to create it first."
    end
    record
  end

  # ── Result helpers ─────────────────────────────────────────────────────────

  def error_result
    msg = if @errors.length == 1
      @errors.first
    else
      "#{@errors.length} error(s). First: #{@errors.take(3).join(' | ')}"
    end
    { success: false, error: msg }
  end
end
