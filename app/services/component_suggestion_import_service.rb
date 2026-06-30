# decor/app/services/component_suggestion_import_service.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Imports ComponentSuggestion records from a CSV file.
# Pattern: identical to ComputerModelImportService.
#
# Expected CSV format (produced by ComponentSuggestionExportService):
#   order_number  — required; must be unique across all existing records
#   description   — optional; may be blank
#   category      — optional; may be blank
#
# Processing strategy:
#   - Duplicate detection: if a ComponentSuggestion with the same order_number
#     (case-insensitive, via the DB LIKE or exists?) already exists, the row is
#     silently skipped. This makes re-importing idempotent.
#   - Blank rows: all-blank rows are silently skipped.
#   - Validation errors: collected; after all rows processed, if any error
#     exists the transaction is rolled back (atomic import — all or nothing).
#   - File validation: nil file, oversized file, non-CSV file are rejected before
#     any rows are processed.
#
# Usage:
#   ComponentSuggestionImportService.process(file)
#
# Returns:
#   { success: true,  count: N }               on success
#   { success: false, error: "message" }       on failure

require "csv"

class ComponentSuggestionImportService
  # Must match ComponentSuggestionExportService::CSV_HEADERS.
  EXPECTED_HEADERS = %w[order_number description category].freeze

  MAX_FILE_SIZE = 10.megabytes

  def initialize(file)
    @file   = file
    @errors = []
    @count  = 0
  end

  # Convenience class method — parallel to ComputerModelImportService.process.
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

  # ── File validation ─────────────────────────────────────────────────────────

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

  # ── CSV parsing ─────────────────────────────────────────────────────────────

  def process_csv
    csv_data = CSV.read(@file.path, headers: true)

    validate_headers!(csv_data.headers)
    return if @errors.any?

    csv_data.each_with_index do |row, index|
      row_num = index + 2  # +2: header row is row 1
      process_row(row, row_num)
    end
  end

  def validate_headers!(headers)
    return if headers.blank?

    missing = EXPECTED_HEADERS - headers.map(&:to_s)
    @errors << "Missing required CSV columns: #{missing.join(', ')}" if missing.any?
  end

  def process_row(row, row_num)
    order_number = row["order_number"]&.strip
    description  = row["description"]&.strip.presence  # nil if blank
    category     = row["category"]&.strip.presence     # nil if blank

    # Silently skip all-blank rows.
    return if row.fields.all?(&:blank?)

    if order_number.blank?
      @errors << "Row #{row_num}: order_number is required"
      return
    end

    # Silently skip if a suggestion with this order_number already exists.
    # Comparison is case-insensitive to match the uniqueness validation.
    return if ComponentSuggestion.exists?(order_number: order_number)

    suggestion = ComponentSuggestion.new(
      order_number: order_number,
      description:  description,
      category:     category
    )

    if suggestion.save
      @count += 1
    else
      @errors << "Row #{row_num}: #{suggestion.errors.full_messages.join(', ')}"
    end
  end

  # ── Result helpers ──────────────────────────────────────────────────────────

  def error_result
    msg = if @errors.length == 1
      @errors.first
    else
      "#{@errors.length} error(s). First: #{@errors.take(3).join(' | ')}"
    end
    { success: false, error: msg }
  end
end
