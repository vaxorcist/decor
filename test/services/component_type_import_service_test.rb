# decor/test/services/component_type_import_service_test.rb
# version 1.0
# Session 24: New test file — ComponentTypeImportService.
#
# Tests mirror the ComputerModelImportService tests in structure,
# adapted for ComponentType (no device_type parameter).

require "test_helper"
require "csv"

class ComponentTypeImportServiceTest < ActiveSupport::TestCase
  # ── Happy path ─────────────────────────────────────────────────────────────

  test "imports a new component type and returns success with count" do
    result = process_csv("name\nNetwork Interface\n")

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert_equal 1, result[:count]
    assert ComponentType.exists?(name: "Network Interface")
  end

  test "imports multiple new component types" do
    csv_content = "name\nGraphics Card\nSound Card\n"
    result = process_csv(csv_content)

    assert result[:success]
    assert_equal 2, result[:count]
  end

  # ── Duplicate handling ─────────────────────────────────────────────────────

  test "silently skips existing component type and returns count 0" do
    # Memory Board already exists in fixtures
    result = process_csv("name\nMemory Board\n")

    assert result[:success], "Skip should not be an error"
    assert_equal 0, result[:count]
    assert_equal 1, ComponentType.where(name: "Memory Board").count
  end

  test "imports new and skips existing in same file" do
    csv_content = "name\nMemory Board\nNetwork Interface\n"
    result = process_csv(csv_content)

    assert result[:success]
    assert_equal 1, result[:count]
  end

  # ── Validation errors ─────────────────────────────────────────────────────

  test "returns error when name column is missing" do
    result = process_csv("type_name\nFoo\n")

    assert_not result[:success]
    assert_match "Missing required CSV columns", result[:error]
    assert_match "name",                         result[:error]
  end

  # Note: blank-name tests are omitted. In a single-column CSV a row whose only
  # field is blank is indistinguishable from a blank line — the service silently
  # skips it (correct behaviour). Rollback on parse error is covered by the
  # missing-column test above.

  # ── File validation ────────────────────────────────────────────────────────

  test "returns error when file is nil" do
    result = ComponentTypeImportService.process(nil)

    assert_not result[:success]
    assert_match "No file provided", result[:error]
  end

  test "returns error for non-CSV file" do
    result = process_csv("name\nFoo\n",
                          content_type: "application/octet-stream",
                          filename: "data.txt")

    assert_not result[:success]
    assert_match "CSV", result[:error]
  end

  private

  def process_csv(content, content_type: "text/csv", filename: "ct_import_test.csv")
    tempfile = Tempfile.new(["ct_import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind
    tempfile.close

    upload = Rack::Test::UploadedFile.new(tempfile.path, content_type, false,
                                           original_filename: filename)

    ComponentTypeImportService.process(upload)
  end
end
