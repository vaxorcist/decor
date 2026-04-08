# decor/app/services/owner_import_service.rb
# version 1.11
# v1.11 (Session 49 — Session G): Replaced member-set duplicate check with
#   owner_group_id exists? check for connection groups.
#   v1.10's member-set approach broke when a port was added to an existing connection:
#   the set changed, so the group was no longer recognised as a duplicate and was
#   saved a second time. Fix: read owner_group_id from the new export column and
#   check @owner.connection_groups.exists?(owner_group_id:) — a direct unique-key
#   lookup. Falls back gracefully to skip (no-op) when owner_group_id is blank
#   (legacy CSVs that predate v1.10 of the exporter).
#   Removed connection_group_exists_for_owner? helper (member-set logic deleted).
#   Rule: always use a stable unique key for duplicate detection in import — never
#   derived properties that can change.
#
# v1.10 (Session 49 — Session G): Fixed connection group duplicate detection
#   (member-set approach — superseded by v1.11).
#   Removed the single ActiveRecord::Base.transaction wrapper that caused all
#   records to be rolled back if any single row failed.
#   Each row is now saved independently. Failed rows are collected in @row_errors
#   and skipped; successful rows are committed immediately.
#   Non-fatal row-level issues (e.g. installed computer not found → software saved
#   as unattached) are collected in @row_warnings — the row IS saved, with a note.
#   @errors is reserved for file-level failures that abort the entire import
#   (bad file, missing required columns in legacy format, connection structure errors).
#
#   Result hash:
#     { success: true,  ...counts..., row_errors: [], row_warnings: [] }  fully clean
#     { success: true,  ...counts..., row_errors: [...], row_warnings: [...] } partial
#     { success: false, error: "..." }  file-level failure (nothing was saved)
#
#   Added component_category import support (v1.8 exports include it; optional on import).
#   Added barter_status import support for computers, peripherals, and components
#   (v1.8 exports include it; defaults to "no_barter" when absent or blank).
#
# v1.7 (Session 48): Section-aware CSV parsing — new format + legacy compat.
#   Format detection; new-format per-section parsing; col() dual-name accessor.
# v1.6 (Session 48): Software feature Session F — software items import.
# v1.5 (Session 41): Appliances → Peripherals merger Phase 4.
# v1.4 (Session 37): Comment rows; sentinel detection; pass 3 connections.
# v1.3 (Session 28): Separate per-device-type counters; peripheral record_type.

require "csv"

class OwnerImportService
  # Legacy global headers (OwnerExportService up to v1.6).
  # Only enforced when importing files produced by the old exporter.
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
    @owner                  = owner
    @file                   = file
    @errors                 = []   # file-level failures — abort the whole import
    @row_errors             = []   # per-row failures — row skipped, not saved
    @row_warnings           = []   # per-row non-fatal notes — row saved with caveat
    @computer_count         = 0
    @peripheral_count       = 0
    @component_count        = 0
    @connection_group_count = 0
    @software_item_count    = 0
  end

  def self.process(owner, file)
    new(owner, file).process
  end

  def process
    validate_file!
    return error_result if @errors.any?

    begin
      process_csv
    rescue => e
      return { success: false, error: "Unexpected error: #{e.message}" }
    end

    return error_result if @errors.any?

    {
      success:                true,
      computer_count:         @computer_count,
      peripheral_count:       @peripheral_count,
      component_count:        @component_count,
      connection_group_count: @connection_group_count,
      software_item_count:    @software_item_count,
      row_errors:             @row_errors,
      row_warnings:           @row_warnings
    }
  end

  private

  # ── File validation ──────────────────────────────────────────────────────────

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

  # ── Format detection & top-level dispatch ────────────────────────────────────

  def process_csv
    content = @file.read
    if new_format?(content)
      process_csv_new_format(content)
    else
      process_csv_legacy_format(content)
    end
  end

  # New format (v1.7 exporter): first non-comment row starts with "!".
  # Legacy format (pre-v1.7):   first non-comment row is the global header.
  def new_format?(content)
    CSV.parse(content, headers: false).each do |row|
      first = row.first&.strip
      next if first.blank? || first.start_with?("#")
      return first.start_with?("!")
    end
    false
  end

  # ── New format: section-aware parsing ───────────────────────────────────────

  def process_csv_new_format(content)
    computer_rows   = []
    component_rows  = []
    connection_rows = []
    software_rows   = []

    sections      = []
    current       = nil
    csv_row_index = 0

    CSV.parse(content, headers: false).each do |raw_row|
      csv_row_index += 1
      first = raw_row.first&.strip

      next if first.blank? || first.start_with?("#")

      if first.start_with?("!")
        sections << current if current
        current = { sentinel: first, headers: nil, rows: [] }
      elsif current && current[:headers].nil?
        current[:headers] = raw_row.map { |c| c&.strip }
      elsif current && current[:headers]
        current[:rows] << [raw_row.map { |c| c }, csv_row_index]
      end
    end
    sections << current if current

    sections.each do |section|
      headers  = section[:headers]
      sentinel = section[:sentinel]
      next unless headers

      section[:rows].each do |raw_row, row_num|
        csv_row     = CSV::Row.new(headers, raw_row)
        record_type = csv_row["record_type"]&.strip&.downcase

        case sentinel
        when /computers/
          case record_type
          when "computer"   then computer_rows << [csv_row, row_num, :computer]
          when "peripheral" then computer_rows << [csv_row, row_num, :peripheral]
          when "appliance"  then computer_rows << [csv_row, row_num, :peripheral]
          end
        when /peripherals/
          case record_type
          when "peripheral" then computer_rows << [csv_row, row_num, :peripheral]
          when "computer"   then computer_rows << [csv_row, row_num, :computer]
          end
        when /components/
          component_rows << [csv_row, row_num] if record_type == "component"
        when /connections/
          case record_type
          when "connection_group"  then connection_rows << [csv_row, row_num, :group]
          when "connection_member" then connection_rows << [csv_row, row_num, :member]
          end
        when /software/
          software_rows << [csv_row, row_num] if record_type == "software_item"
        end
      end
    end

    dispatch_rows(computer_rows, component_rows, connection_rows, software_rows)
  end

  # ── Legacy format: single global header (pre-v1.7 exports) ──────────────────

  def process_csv_legacy_format(content)
    csv_data = CSV.parse(content, headers: true)

    validate_headers!(csv_data.headers)
    return if @errors.any?

    computer_rows   = []
    component_rows  = []
    connection_rows = []
    software_rows   = []

    section = :main

    csv_data.each_with_index do |row, index|
      row_num     = index + 2
      record_type = row["record_type"]&.strip

      next if record_type&.start_with?("#")

      if record_type&.start_with?("!")
        section = record_type.include?("software") ? :software : :connections
        next
      end

      case section
      when :main
        case record_type&.downcase
        when "computer"   then computer_rows  << [row, row_num, :computer]
        when "peripheral" then computer_rows  << [row, row_num, :peripheral]
        when "appliance"  then computer_rows  << [row, row_num, :peripheral]
        when "component"  then component_rows << [row, row_num]
        else
          unless row.fields.all?(&:nil?)
            add_row_error(row_num, "unknown record_type '#{record_type}'")
          end
        end
      when :connections
        case record_type&.downcase
        when "connection_group"  then connection_rows << [row, row_num, :group]
        when "connection_member" then connection_rows << [row, row_num, :member]
        else
          unless row.fields.all?(&:nil?)
            add_row_error(row_num, "unknown record_type '#{record_type}' in connections section")
          end
        end
      when :software
        software_rows << [row, row_num] if record_type&.downcase == "software_item"
      end
    end

    dispatch_rows(computer_rows, component_rows, connection_rows, software_rows)
  end

  def validate_headers!(headers)
    return if headers.blank?

    missing = EXPECTED_HEADERS - headers.map(&:to_s)
    if missing.any?
      @errors << "Missing required CSV columns: #{missing.join(', ')}"
    end
  end

  # ── Shared multi-pass dispatcher ─────────────────────────────────────────────

  # Computers first so components, connections, and software items can reference
  # computers created within the same import file.
  def dispatch_rows(computer_rows, component_rows, connection_rows, software_rows)
    computer_rows.each  { |row, row_num, dt| process_computer_row(row, row_num, dt) }
    component_rows.each { |row, row_num|     process_component_row(row, row_num) }
    process_connection_rows(connection_rows)
    software_rows.each  { |row, row_num|     process_software_row(row, row_num) }
  end

  # ── Column accessor ──────────────────────────────────────────────────────────

  # Returns the first non-blank value found by trying each key in order.
  # First key is the new-format column name; subsequent keys are legacy fallbacks.
  def col(row, *keys)
    keys.each do |key|
      val = row[key]&.strip
      return val if val.present?
    end
    nil
  end

  # ── Error / warning helpers ──────────────────────────────────────────────────

  # Fatal row error — this row will be skipped (not saved).
  def add_row_error(row_num, msg)
    @row_errors << "Row #{row_num}: #{msg}"
  end

  # Non-fatal row warning — the row IS saved, but with a caveat.
  def add_row_warning(row_num, msg)
    @row_warnings << "Row #{row_num}: #{msg}"
  end

  # Returns true if the last row-level error was recorded for this row number.
  # Used by process_* methods to bail early after a fatal lookup failure,
  # without aborting processing of other rows.
  def last_error_for_row?(row_num)
    @row_errors.last&.start_with?("Row #{row_num}:")
  end

  # ── Computer row processing ──────────────────────────────────────────────────

  # New column names: model / order_number / serial_number / condition /
  #                   run_status / history / barter_status
  # Legacy fallbacks: computer_model / computer_order_number / etc.
  # barter_status defaults to "no_barter" when absent or blank.
  def process_computer_row(row, row_num, device_type = :computer)
    serial_number = col(row, "serial_number", "computer_serial_number")
    model_name    = col(row, "model",         "computer_model")

    if serial_number.blank?
      add_row_error(row_num, "serial_number is required for computer records")
      return
    end
    if model_name.blank?
      add_row_error(row_num, "model is required for computer records")
      return
    end

    model = ComputerModel.find_by(name: model_name)
    if model.nil?
      add_row_error(row_num, "Computer model '#{model_name}' not found — ask an admin to create it first.")
      return
    end

    return if @owner.computers.exists?(computer_model: model, serial_number: serial_number)

    condition  = resolve_computer_condition(col(row, "condition",  "computer_condition"),  row_num)
    return if last_error_for_row?(row_num)

    run_status = resolve_run_status(col(row, "run_status", "computer_run_status"), row_num)
    return if last_error_for_row?(row_num)

    barter_status = col(row, "barter_status").presence || "no_barter"

    computer = @owner.computers.build(
      serial_number:      serial_number,
      order_number:       col(row, "order_number", "computer_order_number").presence,
      history:            col(row, "history",       "computer_history").presence,
      computer_model:     model,
      computer_condition: condition,
      run_status:         run_status,
      device_type:        device_type,
      barter_status:      barter_status
    )

    if computer.save
      case device_type
      when :peripheral then @peripheral_count += 1
      else                  @computer_count   += 1
      end
    else
      add_row_error(row_num, computer.errors.full_messages.join(", "))
    end
  end

  # ── Component row processing ─────────────────────────────────────────────────

  # New column names: installed_on_model / installed_on_serial / type / category /
  #                   order_number / serial_number / condition / description / barter_status
  # Legacy fallbacks: (no installed_on_model) / computer_serial_number / component_type / etc.
  # component_category defaults to "integral" when absent or blank.
  # barter_status defaults to "no_barter" when absent or blank.
  def process_component_row(row, row_num)
    type_name = col(row, "type", "component_type")

    if type_name.blank?
      add_row_error(row_num, "type is required for component records")
      return
    end

    component_type = ComponentType.find_by(name: type_name)
    if component_type.nil?
      add_row_error(row_num, "Component type '#{type_name}' not found — ask an admin to create it first.")
      return
    end

    serial_number = col(row, "serial_number", "component_serial_number").presence
    if serial_number && @owner.components.exists?(component_type: component_type,
                                                   serial_number: serial_number)
      return
    end

    condition = resolve_component_condition(
      col(row, "condition", "component_condition"), row_num
    )
    return if last_error_for_row?(row_num)

    computer_serial     = col(row, "installed_on_serial", "computer_serial_number").presence
    computer_model_name = col(row, "installed_on_model").presence  # new-format only; no legacy fallback
    # Use model + serial when available (new-format exports include installed_on_model).
    # Serial-only fallback covers legacy imports that lack the model column.
    # Not-found → nil (saved as spare); consistent with legacy behaviour, no warning.
    computer = if computer_serial.present? && computer_model_name.present?
      @owner.computers
        .joins(:computer_model)
        .find_by(computer_models: { name: computer_model_name }, serial_number: computer_serial)
    elsif computer_serial.present?
      @owner.computers.find_by(serial_number: computer_serial)
    end
    category         = col(row, "category").presence || "integral"
    barter_status    = col(row, "barter_status").presence || "no_barter"

    component = @owner.components.build(
      component_type:      component_type,
      component_condition: condition,
      computer:            computer,
      component_category:  category,
      serial_number:       serial_number,
      order_number:        col(row, "order_number", "component_order_number").presence,
      description:         col(row, "description",  "component_description").presence,
      barter_status:       barter_status
    )

    if component.save
      @component_count += 1
    else
      add_row_error(row_num, component.errors.full_messages.join(", "))
    end
  end

  # ── Software item row processing ─────────────────────────────────────────────

  # New column names: installed_on_model / installed_on_serial / name / version /
  #                   condition / description / history / barter_status
  # Legacy fallbacks: computer_model / computer_serial_number / software_name / etc.
  # barter_status defaults to "no_barter" when absent or blank.
  # Duplicate: same software_name + computer + version → silently skipped.
  def process_software_row(row, row_num)
    name_value = col(row, "name", "software_name")

    if name_value.blank?
      add_row_error(row_num, "name is required for software_item records")
      return
    end

    software_name = resolve_software_name(name_value, row_num)
    return if last_error_for_row?(row_num)

    software_condition = resolve_software_condition(
      col(row, "condition", "software_condition"), row_num
    )
    return if last_error_for_row?(row_num)

    computer_serial = col(row, "installed_on_serial", "computer_serial_number").presence
    computer_model  = col(row, "installed_on_model",  "computer_model").presence
    # resolve_software_computer adds a @row_warning (not @row_error) when the
    # computer is not found — the row IS saved as unattached. last_error_for_row?
    # will NOT fire after a warning, so processing continues.
    computer = resolve_software_computer(computer_serial, computer_model, row_num)

    version = col(row, "version", "software_version").presence

    return if @owner.software_items.exists?(
      software_name: software_name,
      computer:      computer,
      version:       version
    )

    barter_status = col(row, "barter_status", "software_barter_status").presence || "no_barter"

    item = @owner.software_items.build(
      software_name:      software_name,
      software_condition: software_condition,
      computer:           computer,
      version:            version,
      description:        col(row, "description", "software_description").presence,
      history:            col(row, "history",      "software_history").presence,
      barter_status:      barter_status
    )

    if item.save
      @software_item_count += 1
    else
      add_row_error(row_num, item.errors.full_messages.join(", "))
    end
  end

  # Resolves the installed computer for a software_item row.
  # Prefers model+serial (unambiguous) over serial-only.
  # Returns nil (unattached) when computer_serial is blank.
  # Adds a @row_warning (NOT a @row_error) when model+serial is not found —
  # the software item will still be saved as unattached.
  def resolve_software_computer(computer_serial, computer_model_name, row_num)
    return nil if computer_serial.blank?

    if computer_model_name.present?
      computer = @owner.computers
        .joins(:computer_model)
        .find_by(computer_models: { name: computer_model_name }, serial_number: computer_serial)
      if computer.nil?
        add_row_warning(row_num,
          "Computer '#{computer_model_name} \u2013 #{computer_serial}' not found " \
          "for this owner — software item imported as unattached.")
      end
      computer
    else
      @owner.computers.find_by(serial_number: computer_serial)
      # Serial-only lookup: not found → nil (unattached), no warning — consistent
      # with the component "unknown serial → spare" behaviour.
    end
  end

  # ── Connection row processing ────────────────────────────────────────────────

  # Connection processing is still structural (group before members) — a malformed
  # connection section (member before group) adds a file-level @error and aborts
  # connection processing entirely, since there is no sensible partial save for
  # orphaned members.
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
          @errors << "Row #{row_num}: connection_member row appears before any connection_group row"
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

  # New column names: owner_group_id / connection_type_or_model / label / serial_number
  # Legacy fallbacks: (no owner_group_id) / computer_model / computer_order_number / computer_serial_number
  def process_one_connection_group(group_row_data, member_rows_data)
    row, row_num = group_row_data

    # Duplicate check using the stable unique key exported since v1.10.
    # When owner_group_id is present, a direct exists? is all we need.
    # When absent (legacy CSV predating v1.10), owner_group_id.blank? → we have no
    # reliable key, so we skip the check and let the group be created (may duplicate
    # on repeated legacy re-imports, but that is the pre-v1.10 behaviour).
    owner_group_id = col(row, "owner_group_id").presence
    if owner_group_id.present?
      return if @owner.connection_groups.exists?(owner_group_id: owner_group_id)
    end

    type_name = col(row, "connection_type_or_model", "computer_model").presence
    connection_type = nil
    if type_name.present?
      connection_type = ConnectionType.find_by(name: type_name)
      if connection_type.nil?
        add_row_error(row_num, "Connection type '#{type_name}' not found — ask an admin to create it first.")
        return
      end
    end

    label = col(row, "label", "computer_order_number").presence

    member_computers = []
    member_rows_data.each do |member_row, member_row_num|
      computer = find_member_computer(member_row, member_row_num)
      return if last_error_for_row?(member_row_num)
      member_computers << computer
    end

    group = @owner.connection_groups.build(
      connection_type: connection_type,
      label:           label
    )
    member_computers.each { |computer| group.connection_members.build(computer: computer) }

    unless group.save
      add_row_error(row_num, group.errors.full_messages.join(", "))
      return
    end

    @connection_group_count += 1
  end

  # New names: connection_type_or_model (model name for members) / serial_number
  # Legacy fallbacks: computer_model / computer_serial_number
  def find_member_computer(member_row, row_num)
    model_name = col(member_row, "connection_type_or_model", "computer_model").presence
    serial     = col(member_row, "serial_number", "computer_serial_number")

    if serial.blank?
      add_row_error(row_num, "connection_member requires serial_number")
      return nil
    end

    if model_name.present?
      computer = @owner.computers
        .joins(:computer_model)
        .find_by(computer_models: { name: model_name }, serial_number: serial)
      if computer.nil?
        add_row_error(row_num, "Computer '#{model_name} \u2013 #{serial}' not found for this owner")
      end
      computer
    else
      matches = @owner.computers.where(serial_number: serial).to_a
      case matches.size
      when 1 then matches.first
      when 0
        add_row_error(row_num, "Computer with serial '#{serial}' not found for this owner")
        nil
      else
        add_row_error(row_num, "Serial '#{serial}' matches #{matches.size} devices — add the model name to disambiguate.")
        nil
      end
    end
  end

  # ── Lookup helpers ───────────────────────────────────────────────────────────

  def resolve_computer_condition(name, row_num)
    return nil if name.blank?

    record = ComputerCondition.find_by(name: name)
    if record.nil?
      add_row_error(row_num, "Computer condition '#{name}' not found — ask an admin to create it first.")
    end
    record
  end

  def resolve_run_status(name, row_num)
    return nil if name.blank?

    record = RunStatus.find_by(name: name)
    if record.nil?
      add_row_error(row_num, "Run status '#{name}' not found — ask an admin to create it first.")
    end
    record
  end

  def resolve_component_condition(value, row_num)
    return nil if value.blank?

    record = ComponentCondition.find_by(condition: value)
    if record.nil?
      add_row_error(row_num, "Component condition '#{value}' not found — ask an admin to create it first.")
    end
    record
  end

  def resolve_software_name(name, row_num)
    record = SoftwareName.find_by(name: name)
    if record.nil?
      add_row_error(row_num, "Software name '#{name}' not found — ask an admin to create it first.")
    end
    record
  end

  def resolve_software_condition(name, row_num)
    return nil if name.blank?

    record = SoftwareCondition.find_by(name: name)
    if record.nil?
      add_row_error(row_num, "Software condition '#{name}' not found — ask an admin to create it first.")
    end
    record
  end

  # ── Result helpers ───────────────────────────────────────────────────────────

  def error_result
    msg = if @errors.length == 1
      @errors.first
    else
      "#{@errors.length} error(s): #{@errors.take(3).join(' | ')}"
    end
    { success: false, error: msg }
  end
end
