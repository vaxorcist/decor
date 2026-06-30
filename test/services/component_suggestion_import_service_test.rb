# decor/test/services/component_suggestion_import_service_test.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Tests for ComponentSuggestionImportService.
# Pattern: mirrors computer_model_import_service_test.rb.

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

  # ── Duplicate handling ────────────────────────────────────────────────────

  test "silently skips existing order_number and returns count 0" do
    # "DELQA" is a fixture; already exists
    result = process_csv("order_number,description,category\nDELQA,DELQA Ethernet Controller,Option\n")

    assert result[:success], "Duplicate skip must not be an error"
    assert_equal 0, result[:count]
    # Still only one DELQA record
    assert_equal 1, ComponentSuggestion.where(order_number: "DELQA").count
  end

  test "imports new records and skips existing ones in the same file" do
    csv_content = "order_number,description,category\nDELQA,DELQA Ethernet Controller,Option\nBRAND-NEW,New,Test\n"
    result = process_csv(csv_content)

    assert result[:success]
    assert_equal 1, result[:count]
  end

  # ── Blank row handling ────────────────────────────────────────────────────

  test "silently skips all-blank rows" do
    csv_content = "order_number,description,category\nNEW-PART,Some Part,Module\n,,\n"
    result = process_csv(csv_content)

    assert result[:success]
    assert_equal 1, result[:count]
  end

  # ── Validation errors ─────────────────────────────────────────────────────

  test "returns error when order_number column is missing" do
    result = process_csv("part_number,description,category\nFOO,Bar,Baz\n")

    assert_not result[:success]
    assert_match "Missing required CSV columns", result[:error]
    assert_match "order_number",                 result[:error]
  end

  test "returns error when row has blank order_number" do
    # Non-blank row with blank order_number triggers a validation error (not a silent skip)
    result = process_csv("order_number,description,category\n,Some description,Option\n")

    assert_not result[:success]
    assert_match "order_number is required", result[:error]
  end

  test "rolls back all rows when one row has a validation error" do
    # First row is valid, second row exceeds order_number max length (21 chars)
    csv_content = "order_number,description,category\nVALID-NEW,Valid,Option\n#{"X" * 21},Too long,Option\n"
    initial_count = ComponentSuggestion.count

    result = process_csv(csv_content)

    assert_not result[:success]
    # Transaction rolled back — count unchanged
    assert_equal initial_count, ComponentSuggestion.count
  end

  # ── File validation ───────────────────────────────────────────────────────

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
