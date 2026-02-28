# decor/test/services/owner_import_service_test.rb - version 1.0
# Tests for OwnerImportService — verifies CSV import behaviour including the
# two-pass strategy, duplicate skipping, atomicity, and error handling.
#
# File mock: csv_upload(content) creates an ActionDispatch::Http::UploadedFile
# wrapping a Tempfile, giving the service the .path / .size / .content_type /
# .original_filename interface it expects.
#
# Fixture baseline used in tests:
#   computer_models: pdp11_70 ("PDP-11/70"), pdp8 ("PDP-8"), vt100 ("VT100")
#   component_types: memory_board ("Memory Board"), cpu_board ("CPU Board")
#   computer_conditions: original ("Completely original")
#   component_conditions: working (condition: "Working")
#   run_statuses: working ("Working")
#   alice (owners(:one)) — already has SN12345, VAX-780-001, TEST-001
#   bob   (owners(:two)) — already has PDP8-7891, VT100-5432

require "test_helper"
require "tempfile"

class OwnerImportServiceTest < ActiveSupport::TestCase
  setup do
    @alice = owners(:one)
    @bob   = owners(:two)
  end

  # ── Happy path ───────────────────────────────────────────────────────────

  test "imports a single computer row successfully" do
    csv = build_csv([
      ["computer", "PDP-11/70", "NEW-ORD-001", "IMPORT-SN-001",
       "Completely original", "Working", "Test history",
       nil, nil, nil, nil, nil]
    ])

    assert_difference "@alice.computers.count", 1 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success], "Expected success, got: #{result[:error]}"
      assert_equal 1, result[:computer_count]
      assert_equal 0, result[:component_count]
    end
  end

  test "imported computer has correct attribute values" do
    csv = build_csv([
      ["computer", "PDP-11/70", "NEW-ORD-001", "IMPORT-SN-002",
       "Completely original", "Working", "Some history",
       nil, nil, nil, nil, nil]
    ])

    OwnerImportService.process(@alice, csv_upload(csv))

    computer = @alice.computers.find_by!(serial_number: "IMPORT-SN-002")
    assert_equal "PDP-11/70", computer.computer_model.name
    assert_equal "NEW-ORD-001", computer.order_number
    assert_equal "Completely original", computer.computer_condition.name
    assert_equal "Working", computer.run_status.name
    assert_equal "Some history", computer.history
  end

  test "imports a single spare component (no computer)" do
    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil,
       "Memory Board", "MB-ORD-01", "MB-SN-01", "Working", "Spare memory board"]
    ])

    assert_difference "@alice.components.count", 1 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success]
      assert_equal 0, result[:computer_count]
      assert_equal 1, result[:component_count]
    end

    component = @alice.components.find_by!(serial_number: "MB-SN-01")
    assert_nil component.computer,                        "Spare component should have no computer"
    assert_equal "Memory Board",  component.component_type.name
    assert_equal "Working",       component.component_condition.condition
    assert_equal "MB-ORD-01",     component.order_number
    assert_equal "Spare memory board", component.description
  end

  test "imports computers and components in one file" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "BATCH-SN-01", nil, nil, nil,
       nil, nil, nil, nil, nil],
      ["component", nil, nil, nil, nil, nil, nil,
       "CPU Board", nil, nil, nil, "CPU for batch computer"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success]
    assert_equal 1, result[:computer_count]
    assert_equal 1, result[:component_count]
  end

  # ── Two-pass strategy ────────────────────────────────────────────────────

  test "component row can reference a computer created in the same import" do
    # IMPORT-SN-TWO-PASS does not yet exist — computer and component arrive
    # in the same file. The two-pass strategy must process the computer row
    # first so the component row can find it by serial number.
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "IMPORT-SN-TWO-PASS", nil, nil, nil,
       nil, nil, nil, nil, nil],
      ["component", nil, nil, "IMPORT-SN-TWO-PASS", nil, nil, nil,
       "Memory Board", nil, nil, nil, "Attached to new computer"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Expected success, got: #{result[:error]}"

    computer  = @alice.computers.find_by!(serial_number: "IMPORT-SN-TWO-PASS")
    component = @alice.components.find_by!(description: "Attached to new computer")

    assert_equal computer, component.computer, "Component should be attached to the newly imported computer"
  end

  test "component rows appear before computer rows in CSV but still attach correctly" do
    # Component row is listed FIRST in the CSV — two-pass must handle this.
    csv = build_csv([
      ["component", nil, nil, "IMPORT-SN-REVERSED", nil, nil, nil,
       "Memory Board", nil, nil, nil, "Listed before its computer"],
      ["computer", "PDP-11/70", nil, "IMPORT-SN-REVERSED", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Expected success, got: #{result[:error]}"

    computer  = @alice.computers.find_by!(serial_number: "IMPORT-SN-REVERSED")
    component = @alice.components.find_by!(description: "Listed before its computer")

    assert_equal computer, component.computer
  end

  # ── Duplicate skipping ───────────────────────────────────────────────────

  test "re-importing an existing computer serial number is silently skipped" do
    # SN12345 already belongs to alice from fixtures
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "SN12345", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    assert_no_difference "@alice.computers.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success], "Duplicate skip must not cause a failure"
      assert_equal 0, result[:computer_count], "Skipped computer must not be counted"
    end
  end

  test "re-importing an existing component serial number is silently skipped" do
    # Create a component with a known serial number first
    existing = @alice.components.create!(
      component_type: component_types(:memory_board),
      serial_number:  "DUPE-COMP-SN",
      description:    "Original"
    )

    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil,
       "Memory Board", nil, "DUPE-COMP-SN", nil, "Attempted duplicate"]
    ])

    assert_no_difference "@alice.components.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success]
      assert_equal 0, result[:component_count]
    end

    # Original record must be unchanged
    assert_equal "Original", existing.reload.description
  end

  test "component without serial number is always created (no duplicate check)" do
    # Two rows with no serial number — both should be created
    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil,
       "CPU Board", nil, nil, nil, "No serial 1"],
      ["component", nil, nil, nil, nil, nil, nil,
       "CPU Board", nil, nil, nil, "No serial 2"]
    ])

    assert_difference "@alice.components.count", 2 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success]
      assert_equal 2, result[:component_count]
    end
  end

  # ── Unknown computer serial in component → spare (not error) ─────────────

  test "component with unknown computer_serial_number is imported as spare" do
    csv = build_csv([
      ["component", nil, nil, "UNKNOWN-SERIAL-XYZ", nil, nil, nil,
       "Memory Board", nil, "SPARE-DOWNGRADE-SN", nil, "Should become spare"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Unknown computer serial must not cause a failure"

    component = @alice.components.find_by!(serial_number: "SPARE-DOWNGRADE-SN")
    assert_nil component.computer, "Component should be spare when computer serial not found"
  end

  # ── Atomicity ────────────────────────────────────────────────────────────

  test "single bad row rolls back the entire import" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "ATOMIC-GOOD-1", nil, nil, nil,
       nil, nil, nil, nil, nil],
      # Bad row: computer_model does not exist
      ["computer", "NONEXISTENT MODEL", nil, "ATOMIC-BAD-1", nil, nil, nil,
       nil, nil, nil, nil, nil],
      ["computer", "PDP-11/70", nil, "ATOMIC-GOOD-2", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    assert_no_difference "@alice.computers.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      refute result[:success], "Expected failure"
      assert_match "NONEXISTENT MODEL", result[:error]
    end

    # Neither good row should have been saved
    refute @alice.computers.exists?(serial_number: "ATOMIC-GOOD-1")
    refute @alice.computers.exists?(serial_number: "ATOMIC-GOOD-2")
  end

  # ── Required field validation ─────────────────────────────────────────────

  test "computer row without serial_number fails with descriptive error" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, nil, nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "computer_serial_number", result[:error]
  end

  test "computer row without computer_model fails with descriptive error" do
    csv = build_csv([
      ["computer", nil, nil, "NO-MODEL-SN", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "computer_model", result[:error]
  end

  test "component row without component_type fails with descriptive error" do
    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil,
       nil, nil, nil, nil, "No type given"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "component_type", result[:error]
  end

  # ── Lookup validation ─────────────────────────────────────────────────────

  test "unknown computer_model name fails with descriptive error" do
    csv = build_csv([
      ["computer", "Does Not Exist 9000", nil, "LOOKUP-SN-01", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "Does Not Exist 9000", result[:error]
  end

  test "unknown component_type name fails with descriptive error" do
    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil,
       "Phantom Type", nil, nil, nil, "Some component"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "Phantom Type", result[:error]
  end

  test "unknown computer_condition name fails with descriptive error" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "COND-ERR-SN", "Nonexistent Condition",
       nil, nil, nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "Nonexistent Condition", result[:error]
  end

  test "unknown component_condition name fails with descriptive error" do
    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil,
       "Memory Board", nil, nil, "Phantom Condition", "Some component"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "Phantom Condition", result[:error]
  end

  test "unknown run_status name fails with descriptive error" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "RS-ERR-SN", nil, "Phantom Status",
       nil, nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "Phantom Status", result[:error]
  end

  # ── Header validation ─────────────────────────────────────────────────────

  test "CSV with missing required headers fails" do
    bad_csv = "record_type,computer_model\ncomputer,PDP-11/70\n"

    result = OwnerImportService.process(@alice, csv_upload(bad_csv))
    refute result[:success]
    assert_match "Missing required CSV columns", result[:error]
  end

  # ── Unknown record_type ───────────────────────────────────────────────────

  test "unknown record_type value fails with descriptive error" do
    csv = build_csv([
      ["widget", "PDP-11/70", nil, "UNKNOWN-TYPE-SN", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "widget", result[:error]
  end

  # ── File validation ───────────────────────────────────────────────────────

  test "nil file fails gracefully" do
    result = OwnerImportService.process(@alice, nil)
    refute result[:success]
    assert_match "No file provided", result[:error]
  end

  test "non-CSV file is rejected" do
    upload = csv_upload("some content", filename: "data.txt", content_type: "text/plain")
    result = OwnerImportService.process(@alice, upload)
    refute result[:success]
    assert_match "CSV", result[:error]
  end

  private

  # ── Helpers ────────────────────────────────────────────────────────────

  # Build a CSV string from an array of value arrays.
  # Each inner array must have exactly 12 values matching CSV_HEADERS column order.
  def build_csv(rows)
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      rows.each { |row| csv << row }
    end
  end

  # Wrap a CSV string in an ActionDispatch::Http::UploadedFile so the service
  # receives the same interface as a real browser file upload.
  def csv_upload(content, filename: "test_import.csv", content_type: "text/csv")
    tempfile = Tempfile.new(["import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      tempfile:     tempfile,
      filename:     filename,
      type:         content_type,
      head:         "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\""
    )
  end
end
