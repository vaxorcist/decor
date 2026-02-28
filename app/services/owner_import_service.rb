# decor/app/services/owner_import_service.rb
# version 1.0
# Service object that parses a CSV file and creates computers and components
# for the given owner.
#
# Expected CSV format: as produced by OwnerExportService (see that file for
# full column reference). record_type must be "computer" or "component".
#
# Processing strategy:
#   - Two-pass within one transaction: all computer rows processed first, then
#     all component rows. This allows component rows to reference computers that
#     were just created in the same import (via computer_serial_number FK).
#   - Duplicate handling:
#       Computer: skipped (no error) if the owner already has a computer with
#                 the same serial_number.
#       Component: skipped (no error) if the owner already has a component with
#                  the same serial_number (when serial_number is present).
#                  Components without a serial_number are always created.
#   - If a component references a computer_serial_number that is not found
#     among the owner's computers (neither pre-existing nor newly imported),
#     the component is created as a spare (computer: nil) rather than failing.
#     This is intentional: the user may import components independently of
#     their computers.
#   - Any validation error on a row is collected; after all rows are processed,
#     if ANY error exists the entire transaction is rolled back (atomic import).
#
# Correct model / association names (as of Session 7 renames):
#   ComputerCondition   association: computer_condition   column: name
#   ComponentCondition  association: component_condition  column: condition  ← note
#   ComputerModel       column: name
#   ComponentType       column: name
#   RunStatus           column: name

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
    @computer_count  = 0
    @component_count = 0
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

      { success: true, computer_count: @computer_count, component_count: @component_count }
    rescue ActiveRecord::Rollback
      # Rollback was raised by us after collecting errors — already in error_result path above.
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

    # Separate rows into two buckets for the two-pass strategy.
    # Preserve original row numbers (index + 2 because headers occupy row 1).
    computer_rows  = []
    component_rows = []

    csv_data.each_with_index do |row, index|
      row_num = index + 2
      case row["record_type"]&.strip&.downcase
      when "computer"  then computer_rows  << [row, row_num]
      when "component" then component_rows << [row, row_num]
      else
        # Blank rows (all fields nil) are silently skipped.
        # Unknown record_type values get a warning.
        unless row.fields.all?(&:nil?)
          @errors << "Row #{row_num}: unknown record_type '#{row['record_type']}' (expected 'computer' or 'component')"
        end
      end
    end

    # Pass 1: computers — so that pass 2 can find them by serial number.
    computer_rows.each  { |row, row_num| process_computer_row(row, row_num) }
    # Pass 2: components — can reference computers created in pass 1.
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

  def process_computer_row(row, row_num)
    serial_number = row["computer_serial_number"]&.strip
    model_name    = row["computer_model"]&.strip

    # Required fields
    if serial_number.blank?
      @errors << "Row #{row_num}: computer_serial_number is required for computer records"
      return
    end
    if model_name.blank?
      @errors << "Row #{row_num}: computer_model is required for computer records"
      return
    end

    # Skip silently if this owner already has a computer with this serial number.
    # (Idempotent re-import behaviour — re-importing the same export is safe.)
    return if @owner.computers.exists?(serial_number: serial_number)

    # Resolve computer_model (must already exist — we never create lookup data)
    model = ComputerModel.find_by(name: model_name)
    if model.nil?
      @errors << "Row #{row_num}: Computer model '#{model_name}' not found. " \
                 "Ask an admin to create it first."
      return
    end

    # Resolve computer_condition (optional)
    condition = resolve_computer_condition(row["computer_condition"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")  # bail if resolve just added an error

    # Resolve run_status (optional)
    run_status = resolve_run_status(row["computer_run_status"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    computer = @owner.computers.build(
      serial_number:      serial_number,
      order_number:       row["computer_order_number"]&.strip.presence,
      history:            row["computer_history"]&.strip.presence,
      computer_model:     model,
      computer_condition: condition,
      run_status:         run_status
    )

    if computer.save
      @computer_count += 1
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

    # Skip silently if the owner already has a component with this serial number.
    serial_number = row["component_serial_number"]&.strip.presence
    if serial_number && @owner.components.exists?(serial_number: serial_number)
      return
    end

    # Resolve component_condition (optional).
    # Note: ComponentCondition uses column "condition", not "name".
    condition = resolve_component_condition(row["component_condition"]&.strip, row_num)
    return if @errors.last&.start_with?("Row #{row_num}")

    # Resolve parent computer via computer_serial_number (optional).
    # If the serial is present but not found, the component is imported as a spare
    # rather than failing — the user may import components without their computers.
    computer = nil
    computer_serial = row["computer_serial_number"]&.strip.presence
    if computer_serial
      computer = @owner.computers.find_by(serial_number: computer_serial)
      # No error if not found — silent downgrade to spare (see method comment above).
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

  # Resolves a ComputerCondition by name. Returns nil when value is blank (optional field).
  # Adds an error and returns nil when the value is present but not found.
  def resolve_computer_condition(name, row_num)
    return nil if name.blank?

    record = ComputerCondition.find_by(name: name)
    if record.nil?
      @errors << "Row #{row_num}: Computer condition '#{name}' not found. " \
                 "Ask an admin to create it first."
    end
    record
  end

  # Resolves a RunStatus by name. Same nil/error behaviour as above.
  def resolve_run_status(name, row_num)
    return nil if name.blank?

    record = RunStatus.find_by(name: name)
    if record.nil?
      @errors << "Row #{row_num}: Run status '#{name}' not found. " \
                 "Ask an admin to create it first."
    end
    record
  end

  # Resolves a ComponentCondition by its "condition" column (not "name" — different table).
  # Same nil/error behaviour as the helpers above.
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
