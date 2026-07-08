# decor/test/services/component_suggestion_import_service_test.rb
# version 2.0
# Session 67: Phase 4 item 3 — full rewrite to match
# ComponentSuggestionImportService v2.0's new delete-all + bulk-insert
# strategy. Several v1.0 tests no longer apply and were removed or rewritten:
#
#   REMOVED — "silently skips existing order_number and returns count 0":
#     No longer true. v2.0 deletes ALL existing rows unconditionally before
#     importing, so re-importing "DELQA" now RE-CREATES it rather than
#     skipping it. Replaced with tests that explicitly verify the delete-all
#     behavior (old fixture rows are gone after import unless also present
#     in the new file) and the new in-file duplicate handling (via
#     insert_all's unique_by, not a per-row exists? check).
#
#   REMOVED — "rolls back all rows when one row has a validation error"
#     (previously tested an order_number > 20 chars): insert_all bypasses
#     Rails model validations entirely (confirmed, accepted tradeoff — see
#     the service's file header). An over-length order_number is no longer
#     an import error; it is stored as-is (SQLite does not enforce VARCHAR
#     length at runtime regardless). Replaced with a test that explicitly
#     confirms this new behavior, so a future regression here is caught
#     rather than silently changing behavior again.
#
#   UNCHANGED — blank-row skip, missing order_number header, blank
#     order_number in an otherwise-present row, nil file, non-CSV file:
#     all of these are still checked in Ruby before any DB write, exactly
#     as in v1.0.
#
#   NEW — manual: nil is always set on every imported row; batching across
#     more than one BATCH_SIZE (1000) slice still imports every row correctly.
#
# Pattern: mirrors computer_model_import_service_test.rb for structure
# (private process_csv helper building a Rack::Test::UploadedFile).

require "test_helper"
require "csv"

class ComponentSuggestionImportServiceTest < ActiveSupport::TestCase
  # ── Happy path ────────────────────────────────────────────────────────────

  test "imports a new suggestion and returns success with count" do
    result = process_csv("order_number,description,category\nUNIQ-NEW,New Part,Option\n")

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert_equal 1, result[:count]

    suggestion = ComponentSuggestion.find_by!(order_number: "UNIQ-NEW")
    assert_equal "New Part", suggestion.description
    assert_equal "Option",   suggestion.category
  end

  test "imports multiple new suggestions" do
    csv_content = "order_number,description,category\nPART-A,Part A,Module\nPART-B,Part B,Assembly\n"
    result = process_csv(csv_content)

    assert result[:success]
    assert_equal 2, result[:count]
  end

  test "imports suggestion without description or category" do
    result = process_csv("order_number,description,category\nORDER-ONLY,,\n")

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert_equal 1, result[:count]

    suggestion = ComponentSuggestion.find_by!(order_number: "ORDER-ONLY")
    assert_nil suggestion.description
    assert_nil suggestion.category
  end

  test "imported rows always have manual: nil, even if a same-named fixture had a value" do
    # Confirms bulk-imported rows are always treated as untouched, regardless
    # of anything that existed before the delete-all wipe.
    result = process_csv("order_number,description,category\nDELQA,DELQA Ethernet Controller,Option\n")

    assert result[:success]
    suggestion = ComponentSuggestion.find_by!(order_number: "DELQA")
    assert_nil suggestion.manual
  end

  # ── Delete-all behavior (Session 67 — the core Phase 4 rewrite) ──────────

  test "deletes all existing rows before importing, including fixtures not present in the new file" do
    # Sanity check the baseline: fixtures exist before the import runs.
    assert ComponentSuggestion.exists?(order_number: "M7516")

    # New file does NOT include "M7516" — under the old v1.0 behavior it
    # would have simply been left alone; under v2.0 it must be gone.
    result = process_csv("order_number,description,category\nBRAND-NEW-ONLY,Brand New,Test\n")

    assert result[:success]
    assert_not ComponentSuggestion.exists?(order_number: "M7516"),
               "v2.0 must delete ALL existing rows unconditionally, including ones absent from the new file"
    assert ComponentSuggestion.exists?(order_number: "BRAND-NEW-ONLY")
  end

  test "deletes manually-flagged rows too — no preservation of any kind" do
    # Confirmed Session 66: manual rows get NO special treatment in the
    # import — the admin is expected to have downloaded them first via
    # ManualComponentSuggestionsExportService if they wanted a record.
    manual_row = ComponentSuggestion.create!(order_number: "WAS-MANUAL", manual: "added")

    result = process_csv("order_number,description,category\nSOMETHING-ELSE,Desc,Cat\n")

    assert result[:success]
    assert_not ComponentSuggestion.exists?(id: manual_row.id),
               "manually-flagged rows must be deleted unconditionally, same as any other row"
  end

  test "result count after import equals ComponentSuggestion.count (table was fully replaced)" do
    result = process_csv("order_number,description,category\nONLY-ROW-A,A,Cat\nONLY-ROW-B,B,Cat\n")

    assert result[:success]
    assert_equal 2, result[:count]
    assert_equal 2, ComponentSuggestion.count,
                 "since the table is fully replaced, total count must equal the imported count"
  end

  # ── In-file duplicate handling (replaces the old per-row exists? check) ──

  test "keeps the first occurrence when the same order_number appears twice in one file" do
    csv_content = "order_number,description,category\n" \
                  "DUP-ORDER,First Description,First Cat\n" \
                  "DUP-ORDER,Second Description,Second Cat\n"

    result = process_csv(csv_content)

    assert result[:success]
    assert_equal 1, ComponentSuggestion.where(order_number: "DUP-ORDER").count,
                 "the unique index (via insert_all unique_by:) must prevent a duplicate row"
    suggestion = ComponentSuggestion.find_by!(order_number: "DUP-ORDER")
    assert_equal "First Description", suggestion.description,
                 "ON CONFLICT DO NOTHING means the first occurrence in file order wins"
  end

  # ── Blank row handling (unchanged from v1.0) ──────────────────────────────

  test "silently skips all-blank rows" do
    csv_content = "order_number,description,category\nNEW-PART,Some Part,Module\n,,\n"
    result = process_csv(csv_content)

    assert result[:success]
    assert_equal 1, result[:count]
  end

  # ── Validation — header and blank order_number (unchanged, Ruby-level) ───

  test "returns error when order_number column is missing" do
    result = process_csv("part_number,description,category\nFOO,Bar,Baz\n")

    assert_not result[:success]
    assert_match "Missing required CSV columns", result[:error]
    assert_match "order_number",                 result[:error]
  end

  test "returns error when row has blank order_number" do
    # Non-blank row with blank order_number triggers a Ruby-level error before
    # any DB write (not a silent skip, and not an insert_all/DB-level failure).
    result = process_csv("order_number,description,category\n,Some description,Option\n")

    assert_not result[:success]
    assert_match "order_number is required", result[:error]
  end

  test "returns error when file has no valid rows at all" do
    result = process_csv("order_number,description,category\n,,\n")

    assert_not result[:success]
    assert_match "No valid rows found", result[:error]
  end

  test "does not delete existing rows when the file fails validation" do
    # Confirms the delete_all + insert_all pair is wrapped in one transaction:
    # a Ruby-level validation failure (caught BEFORE the transaction even
    # starts) must leave the existing table completely untouched.
    assert ComponentSuggestion.exists?(order_number: "DELQA")

    result = process_csv("part_number,description,category\nFOO,Bar,Baz\n") # missing order_number column

    assert_not result[:success]
    assert ComponentSuggestion.exists?(order_number: "DELQA"),
           "existing data must survive a header-validation failure untouched"
  end

  # ── Changed behavior: insert_all bypasses model validations (Session 67) ─

  test "an order_number longer than 20 characters is stored as-is, not rejected" do
    # This is a deliberate, accepted tradeoff of the v2.0 rewrite: insert_all
    # bypasses Rails model validations entirely, and SQLite does not enforce
    # VARCHAR(20) at runtime (see RAILS_SPECIFICS.md "SQLite — VARCHAR Length
    # Enforcement"). Documented here so a future change to this behavior is a
    # deliberate decision, not an accidental regression.
    long_order_number = "A" * 25
    result = process_csv("order_number,description,category\n#{long_order_number},Desc,Cat\n")

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert ComponentSuggestion.exists?(order_number: long_order_number)
  end

  # ── File validation (unchanged from v1.0) ─────────────────────────────────

  test "returns error when file is nil" do
    result = ComponentSuggestionImportService.process(nil)

    assert_not result[:success]
    assert_match "No file provided", result[:error]
  end

  test "returns error for non-CSV file" do
    result = process_csv("order_number,description,category\nFOO,Bar,Baz\n",
                          content_type: "application/octet-stream",
                          filename: "data.txt")

    assert_not result[:success]
    assert_match "CSV", result[:error]
  end

  # ── Batching across more than one BATCH_SIZE slice ────────────────────────

  test "imports correctly across multiple insert_all batches" do
    # ComponentSuggestionImportService::BATCH_SIZE is 1000 — build a file
    # with enough rows to force at least two insert_all calls via each_slice,
    # confirming the batching loop doesn't drop or duplicate any rows at the
    # slice boundary.
    row_count = ComponentSuggestionImportService::BATCH_SIZE + 250
    csv_lines = (1..row_count).map { |i| "BATCH-ROW-#{i.to_s.rjust(5, '0')},Desc #{i},Cat" }
    csv_content = "order_number,description,category\n#{csv_lines.join("\n")}\n"

    result = process_csv(csv_content)

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert_equal row_count, result[:count]
    assert_equal row_count, ComponentSuggestion.count
  end

  private

  def process_csv(content,
                  content_type: "text/csv",
                  filename: "test_import.csv")
    tempfile = Tempfile.new(["cs_import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind
    tempfile.close

    upload = Rack::Test::UploadedFile.new(tempfile.path, content_type, false,
                                           original_filename: filename)

    ComponentSuggestionImportService.process(upload)
  end
end
