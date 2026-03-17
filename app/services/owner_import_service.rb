# decor/app/services/owner_import_service.rb
# version 1.3
# Session 28: Two fixes:
#   1. Duplicate check now scopes by (owner, model, serial) instead of just
#      (owner, serial). The old check used only serial number, so a VT220 with
#      serial "unknown" blocked import of a VT320 with the same serial "unknown"
#      — even though they are physically different devices. Fix: resolve the model
#      first, then check @owner.computers.exists?(computer_model: model,
#      serial_number: serial_number). Model resolution is now the first step in
#      process_computer_row so it is available for the duplicate check.
#   2. Replaced single @computer_count with three separate counters:
#      @computer_count, @appliance_count, @peripheral_count. The result hash
#      now returns all three so the controller can report them separately in
#      the flash message.
# Session 16: device_type support — "appliance" is now a valid record_type.
# Session 28: peripheral support — "peripheral" is now a valid record_type.

require "csv"

class OwnerImportService
  # The exact headers the import expects — must match OwnerExportService::CSV_HEADERS.
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
    @owner  = owner
    @file   = file
    @errors = []
    # Separate counters for each device type so the flash message can be precise.
    @computer_count   = 0
    @appliance_count  = 0
    @peripheral_count = 0
    @component_count  = 0
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
        success:          true,
        computer_count:   @computer_count,
        appliance_count:  @appliance_count,
        peripheral_count: @peripheral_count,
        component_count:  @component_count
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

  # ── CSV parsing & two-pass dispatch ───────────────────────────────────────

  def process_csv
    csv_data = CSV.read(@file.path, headers: true)

    validate_headers!(csv_data.headers)
    return if @errors.any?

    computer_rows  = []
    component_rows = []

    csv_data.each_with_index do |row, index|
      row_num = index + 2
      case row["record_type"]&.strip&.downcase
      when "computer"
        computer_rows  << [row, row_num, :computer]
      when "appliance"
        computer_rows  << [row, row_num, :appliance]
      when "peripheral"
        computer_rows  << [row, row_num, :peripheral]
      when "component"
        component_rows << [row, row_num]
      else
        unless row.fields.all?(&:nil?)
          @errors << "Row #{row_num}: unknown record_type '#{row['record_type']}' " \
                     "(expected 'computer', 'appliance', 'peripheral', or 'component')"
        end
      end
    end

    # Pass 1: all device rows — so pass 2 can find them by serial number.
    computer_rows.each  { |row, row_num, device_type| process_computer_row(row, row_num, device_type) }
    # Pass 2: component rows — can reference devices created in pass 1.
    component_rows.each { |row, row_num| process_component_row(row, row_num) }
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
  # ORDER OF STEPS — model is resolved FIRST so the duplicate check can scope
  # by (owner, model, serial). The old order resolved model after the duplicate
  # check, which meant the check only scoped by (owner, serial) and incorrectly
  # blocked import of different-model devices with the same serial number
  # (e.g. VT220 "unknown" blocked VT320 "unknown" for the same owner).
  def process_computer_row(row, row_num, device_type = :computer)
    serial_number = row["computer_serial_number"]&.strip
    model_name    = row["computer_model"]&.strip

    # Step 1 — required field presence checks.
    if serial_number.blank?
      @errors << "Row #{row_num}: computer_serial_number is required for computer records"
      return
    end
    if model_name.blank?
      @errors << "Row #{row_num}: computer_model is required for computer records"
      return
    end

    # Step 2 — resolve computer_model BEFORE the duplicate check.
    # Model must be known to scope the duplicate check correctly.
    model = ComputerModel.find_by(name: model_name)
    if model.nil?
      @errors << "Row #{row_num}: Computer model '#{model_name}' not found. " \
                 "Ask an admin to create it first."
      return
    end

    # Step 3 — duplicate check: skip silently if (owner, model, serial) already exists.
    # Scoping by model is essential: a VT220 "unknown" and a VT320 "unknown" owned by
    # the same person are physically different devices and must both be importable.
    return if @owner.computers.exists?(computer_model: model, serial_number: serial_number)

    # Step 4 — resolve optional lookup associations.
    condition = resolve_computer_condition(row["computer_condition"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    run_status = resolve_run_status(row["computer_run_status"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    # Step 5 — build and save.
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
      # Increment the counter for the specific device type so the flash message
      # can report each type separately.
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

    # Skip silently if the owner already has a component with this serial number
    # and type (scoped by owner + type per the unique index on components).
    serial_number = row["component_serial_number"]&.strip.presence
    if serial_number && @owner.components.exists?(component_type: component_type,
                                                   serial_number: serial_number)
      return
    end

    condition = resolve_component_condition(row["component_condition"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    # Resolve parent device via computer_serial_number (optional).
    # If not found, component is imported as a spare rather than failing.
    computer = nil
    computer_serial = row["computer_serial_number"]&.strip.presence
    if computer_serial
      computer = @owner.computers.find_by(serial_number: computer_serial)
    end

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
