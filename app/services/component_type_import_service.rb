# decor/app/services/component_type_import_service.rb
# version 1.0
# Session 24: New service — imports ComponentType reference data from CSV.
#
# Parses a CSV file produced by ComponentTypeExportService (or any CSV with a
# "name" column) and creates ComponentType records.
#
# Expected CSV format:
#   name — component type name (required); must match ComponentTypeExportService::CSV_HEADERS
#
# Processing strategy:
#   - Duplicate handling: a row is silently skipped if a ComponentType with the
#     same name already exists. This makes re-importing the same CSV safe.
#   - Any validation error on a row is collected. After all rows are processed,
#     if ANY error exists the entire transaction is rolled back (atomic import).
#   - Blank rows (all fields nil/blank) are silently skipped.
#
# Usage:
#   ComponentTypeImportService.process(file)
#
# Returns:
#   { success: true,  count: N }                on success
#   { success: false, error: "message" }        on failure

require "csv"

class ComponentTypeImportService
  # Must match ComponentTypeExportService::CSV_HEADERS.
  EXPECTED_HEADERS = %w[name].freeze

  MAX_FILE_SIZE = 10.megabytes

  def initialize(file)
    @file   = file
    @errors = []
    @count  = 0
  end

  # Convenience class method.
  def self.process(file)
    new(file).process
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

      { success: true, count: @count }
    rescue ActiveRecord::Rollback
      error_result
    rescue => e
      { success: false, error: "Unexpected error: #{e.message}" }
    end
  end

  private

  # ── File validation ────────────────────────────────────────────────────

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

  # ── CSV parsing ────────────────────────────────────────────────────────

  def process_csv
    csv_data = CSV.read(@file.path, headers: true)

    validate_headers!(csv_data.headers)
    return if @errors.any?

    csv_data.each_with_index do |row, index|
      row_num = index + 2  # +2 because headers occupy row 1
      process_row(row, row_num)
    end
  end

  def validate_headers!(headers)
    return if headers.blank?

    missing = EXPECTED_HEADERS - headers.map(&:to_s)
    @errors << "Missing required CSV columns: #{missing.join(', ')}" if missing.any?
  end

  def process_row(row, row_num)
    name = row["name"]&.strip

    # Silently skip blank rows
    return if name.blank? && row.fields.all?(&:blank?)

    if name.blank?
      @errors << "Row #{row_num}: name is required"
      return
    end

    # Silently skip if a component type with this name already exists.
    return if ComponentType.exists?(name: name)

    ct = ComponentType.new(name: name)

    if ct.save
      @count += 1
    else
      @errors << "Row #{row_num}: #{ct.errors.full_messages.join(', ')}"
    end
  end

  # ── Result helpers ─────────────────────────────────────────────────────

  def error_result
    msg = if @errors.length == 1
      @errors.first
    else
      "#{@errors.length} error(s). First: #{@errors.take(3).join(' | ')}"
    end
    { success: false, error: msg }
  end
end
