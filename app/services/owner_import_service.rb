# decor/app/services/owner_import_service.rb
# version 1.4
# Session 37: Three additions — all handled inside process_csv and new private methods:
#
#   1. Comment rows: any row whose record_type starts with '#' is silently skipped.
#      This lets humans annotate exported CSV files without breaking import.
#
#   2. Sentinel detection: any row whose record_type starts with '!' puts the
#      parser into connections mode. All subsequent rows are treated as
#      connection_group or connection_member rows.
#      Expected sentinel value: "! --- connections ---".
#
#   3. Pass 3 — connections: after devices (pass 1) and components (pass 2),
#      connection_group and connection_member rows are processed sequentially.
#      - A connection_group row opens a new group. Column reuse:
#          computer_model        → connection_type name (optional)
#          computer_order_number → group label (optional)
#      - connection_member rows that follow belong to that group. Column reuse:
#          computer_model         → device model name (for serial disambiguation)
#          computer_serial_number → device serial number (required)
#      - The group (and its built members) is saved together. Rails autosaves
#        has_many-built records when the parent saves, so the group-level
#        validations (minimum_two_members, all_members_belong_to_owner) run
#        on a fully-assembled group.
#      - @connection_group_count incremented for each successfully saved group.
#      - No duplicate detection for connection groups — groups do not have a
#        single-column natural key. Connections are always imported as new.
#
#   Added @connection_group_count to initialize, process (result hash).
#   Updated unknown record_type error message to mention the sentinel.
#
# Session 28: Two fixes: duplicate check scoped to (owner, model, serial);
#   separate counters for computer_count, appliance_count, peripheral_count.
# Session 16: device_type support — "appliance" record_type.
# Session 28 (peripheral): "peripheral" record_type.

require "csv"

class OwnerImportService
  # The exact headers the import expects — must match OwnerExportService::CSV_HEADERS.
  # Connection rows reuse existing columns; no new headers are needed.
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
    @appliance_count  = 0
    @peripheral_count = 0
    @component_count  = 0
    # Counts successfully saved connection groups (not members — the group
    # is the unit of import; members are part of it).
    @connection_group_count = 0
  end

  # Convenience class method — parallel to BulkUploadService.process(file).
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
        appliance_count:        @appliance_count,
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
      row_num     = index + 2                        # +2: header row is row 1
      record_type = row["record_type"]&.strip

      # Skip comment rows — any record_type starting with '#' is a human-readable
      # annotation. The export writes a comment header row as the first data row.
      next if record_type&.start_with?("#")

      # Detect the connections sentinel. Any record_type starting with '!' puts
      # the parser into connections mode for all subsequent rows.
      # Expected value: "! --- connections ---"
      if record_type&.start_with?("!")
        in_connections_mode = true
        next
      end

      if in_connections_mode
        # After the sentinel, only connection_group and connection_member are valid.
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
        # Before the sentinel, only device and component rows are valid.
        case record_type&.downcase
        when "computer"   then computer_rows  << [row, row_num, :computer]
        when "appliance"  then computer_rows  << [row, row_num, :appliance]
        when "peripheral" then computer_rows  << [row, row_num, :peripheral]
        when "component"  then component_rows << [row, row_num]
        else
          unless row.fields.all?(&:nil?)
            @errors << "Row #{row_num}: unknown record_type '#{record_type}' " \
                       "(valid: 'computer', 'appliance', 'peripheral', 'component'; " \
                       "put 'connection_group'/'connection_member' rows after " \
                       "'! --- connections ---')"
          end
        end
      end
    end

    # Pass 1: all device rows — so pass 2 can find them by serial number,
    # and pass 3 can find them as connection members.
    computer_rows.each { |row, row_num, device_type| process_computer_row(row, row_num, device_type) }

    # Pass 2: component rows — references devices created in pass 1.
    component_rows.each { |row, row_num| process_component_row(row, row_num) }

    # Pass 3: connection rows — references devices created in pass 1.
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

  # Processes a computer, appliance, or peripheral row.
  # device_type: :computer (default), :appliance, or :peripheral.
  #
  # Steps in order:
  #   1. Required field presence checks
  #   2. Resolve computer_model FIRST (needed by duplicate check)
  #   3. Duplicate check: skip silently if (owner, model, serial) already exists
  #   4. Resolve optional lookup associations
  #   5. Build and save
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

    # Skip silently if (owner, model, serial) already exists. Scoping by model
    # is essential: a VT220 "unknown" and a VT320 "unknown" owned by the same
    # person are physically different devices and must both be importable.
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
      when :appliance  then @appliance_count  += 1
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

  # Group the flat connection_rows array into (group_row, member_rows[]) structs,
  # then process each group. Errors accumulate; one failing group does not
  # prevent processing of subsequent groups.
  #
  # A connection_member row before any connection_group row is an error — it is
  # unclear which group the member should belong to.
  def process_connection_rows(connection_rows)
    return if connection_rows.empty?

    # Collect consecutive member rows with their preceding group row.
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

  # Process a single connection group: resolve type + label from the group row,
  # build members from the member rows, then save the group and all its members
  # in one call (Rails autosaves has_many-built associations on parent save).
  #
  # Column reuse for group rows:
  #   computer_model        → connection_type name (optional, blank = no type)
  #   computer_order_number → group label (optional)
  #
  # No duplicate detection: connection groups lack a single-column natural key.
  # Re-importing will create a new group alongside any existing one.
  def process_one_connection_group(group_row_data, member_rows_data)
    row, row_num = group_row_data

    # Resolve connection_type from the computer_model column (optional).
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

    # Build the group without saving yet — validation requires members to be
    # present at save time.
    group = @owner.connection_groups.build(
      connection_type: connection_type,
      label:           label
    )

    # Resolve each member computer and attach it to the group.
    member_rows_data.each do |member_row, member_row_num|
      computer = find_member_computer(member_row, member_row_num)
      # find_member_computer appends to @errors on failure.
      return if @errors.last&.start_with?("Row #{member_row_num}")
      group.connection_members.build(computer: computer)
    end

    # Save group and its built members together. Group-level validations
    # (minimum_two_members, all_members_belong_to_owner) run here.
    unless group.save
      @errors << "Row #{row_num}: #{group.errors.full_messages.join(', ')}"
      return
    end

    @connection_group_count += 1
  end

  # Locate the computer for a connection_member row, scoped to @owner.
  # The member row encodes the device as (model name, serial number).
  # Model name is strongly recommended (disambiguates identical serials across
  # different models). If omitted and the serial is ambiguous, an error is raised.
  def find_member_computer(member_row, row_num)
    model_name = member_row["computer_model"]&.strip.presence
    serial     = member_row["computer_serial_number"]&.strip

    if serial.blank?
      @errors << "Row #{row_num}: connection_member requires computer_serial_number"
      return nil
    end

    if model_name.present?
      # Preferred: scope by owner + model + serial. Handles the case where the same
      # owner has two devices with the same serial but different models.
      computer = @owner.computers
        .joins(:computer_model)
        .find_by(computer_models: { name: model_name }, serial_number: serial)
      if computer.nil?
        @errors << "Row #{row_num}: Computer '#{model_name} — #{serial}' " \
                   "not found for this owner"
      end
      computer
    else
      # Fallback: scope by owner + serial only. Error if ambiguous.
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
