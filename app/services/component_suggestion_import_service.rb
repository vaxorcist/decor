# decor/app/services/component_suggestion_import_service.rb
# version 2.0
# Session 67: Phase 4 — full rewrite. Root cause of production timeouts
# (confirmed Session 66): the v1.0 implementation checked every incoming CSV
# row against existing records via ComponentSuggestion.exists?(order_number:),
# an O(n) DB round-trip per row against a table that only grows — at
# ~55,000 rows this took minutes locally and timed out in production.
#
# New strategy, confirmed Session 66 (SESSION_HANDOVER.md "Session 66 Summary"
# item 3):
#   - component_suggestions is a DISPOSABLE MIRROR of the external DEC
#     database, not a record needing reconciliation against prior state.
#   - Delete ALL existing rows unconditionally — including "a"/"m" manually
#     flagged rows. There is NO preservation logic of any kind here. The
#     admin is expected to run "Download Manual Changes" (see
#     Admin::ComponentSuggestionsController#download_manual) BEFORE
#     triggering a re-import if they want a record of manual work; this
#     import service does not do that automatically.
#   - Bulk-insert all new rows with insert_all(unique_by: :order_number),
#     relying entirely on the pre-existing DB unique index on order_number
#     (migration 20260511000100) for duplicate handling. NO app-level
#     duplicate pre-check against the DB is performed — this is the single
#     highest-value fix, eliminating the O(n) per-row lookup entirely.
#   - Within-file duplicates (two rows in the same CSV sharing an
#     order_number) are resolved by the same ON CONFLICT DO NOTHING that
#     unique_by triggers: the first occurrence in file order wins, later
#     duplicates in the same file are silently dropped. This mirrors how
#     the DB index would behave if rows were inserted one at a time.
#   - Every imported row gets manual: nil (the Rails default for an
#     unassigned nullable column) — bulk-imported rows are, by definition,
#     untouched (see component_suggestion.rb v1.1 / ComponentSuggestion#manual
#     enum). Any previously-flagged "a"/"m" row is gone after the delete —
#     the download-first workflow above is the intended way to recover
#     that information if needed, not automatic preservation here.
#
# Expected CSV format (unchanged from v1.0 — produced by
# ComponentSuggestionExportService):
#   order_number  — required; case preserved as given (DB unique index is
#                   NOT case-insensitive at the SQL level, unlike the Rails
#                   model validation — see note in read_and_validate_rows)
#   description   — optional; may be blank
#   category      — optional; may be blank
#
# Row-level validation still happens in Ruby BEFORE any DB write (blank rows
# skipped, missing order_number rejected) — only the expensive per-row
# EXISTENCE CHECK against the database was removed. Rails model validations
# (length limits, uniqueness) are bypassed by insert_all by design — this is
# an accepted tradeoff for bulk-loading data whose source of truth (the DEC
# database) is already trusted. SQLite does not enforce VARCHAR length at
# runtime regardless (see RAILS_SPECIFICS.md "SQLite — VARCHAR Length
# Enforcement"), so an overlength description is stored as-is, not truncated
# or rejected.
#
# Usage:
#   ComponentSuggestionImportService.process(file)
#
# Returns:
#   { success: true,  count: N }               on success
#   { success: false, error: "message" }       on failure — nothing is
#                                               written; the transaction
#                                               (delete + insert) is atomic.

require "csv"

class ComponentSuggestionImportService
  # Must match ComponentSuggestionExportService::CSV_HEADERS.
  EXPECTED_HEADERS = %w[order_number description category].freeze

  MAX_FILE_SIZE = 10.megabytes

  # insert_all is called once per slice rather than once for the whole
  # ~55,000-row file, to keep any single SQL statement (and the params array
  # backing it) to a reasonable size. 1000 was chosen as a conservative
  # default — comfortably below any practical SQLite statement-size limit
  # and still only ~55 round-trips total for the full dataset, a trivial
  # cost compared to the O(n) per-row lookups this replaces.
  BATCH_SIZE = 1000

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

    rows = read_and_validate_rows
    return error_result if @errors.any?

    if rows.empty?
      @errors << "No valid rows found in file"
      return error_result
    end

    ActiveRecord::Base.transaction do
      # Unconditional wipe — see file header. delete_all issues a single
      # DELETE FROM statement; no per-row callbacks fire, which is correct
      # here since ComponentSuggestion has no dependent associations to clean up.
      ComponentSuggestion.delete_all

      rows.each_slice(BATCH_SIZE) do |batch|
        # unique_by: :order_number relies entirely on the existing unique
        # index (migration 20260511000100) — ON CONFLICT (order_number)
        # DO NOTHING. This is what replaces the removed per-row exists?
        # check: duplicate order_numbers within the file are silently
        # skipped (first occurrence wins) instead of being looked up
        # individually against the database.
        ComponentSuggestion.insert_all(batch, unique_by: :order_number)
      end
    end

    @count = rows.size
    { success: true, count: @count }
  rescue => e
    { success: false, error: "Unexpected error: #{e.message}" }
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

  # Reads the whole file into an array of insert_all-ready hashes. Unlike
  # v1.0, this performs NO database reads at all during parsing — every row
  # is validated using only the data already in memory (blank-row skip,
  # order_number presence). This is what makes the O(n) DB-lookup cost
  # disappear entirely, rather than just becoming cheaper.
  def read_and_validate_rows
    csv_data = CSV.read(@file.path, headers: true)

    validate_headers!(csv_data.headers)
    return [] if @errors.any?

    now = Time.current
    rows = []

    csv_data.each_with_index do |row, index|
      row_num = index + 2 # +2: header row is row 1

      # Silently skip all-blank rows (matches v1.0 behavior).
      next if row.fields.all?(&:blank?)

      order_number = row["order_number"]&.strip
      if order_number.blank?
        @errors << "Row #{row_num}: order_number is required"
        next
      end

      rows << {
        order_number: order_number,
        description:  row["description"]&.strip.presence, # nil if blank
        category:     row["category"]&.strip.presence,    # nil if blank
        manual:       nil,                                # untouched bulk-import row
        created_at:   now,
        updated_at:   now
      }
    end

    rows
  end

  def validate_headers!(headers)
    return if headers.blank?

    missing = EXPECTED_HEADERS - headers.map(&:to_s)
    @errors << "Missing required CSV columns: #{missing.join(', ')}" if missing.any?
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
