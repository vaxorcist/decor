# decor/test/services/computer_model_import_service_test.rb
# version 1.2
# v1.2 (Session 41): Appliances → Peripherals merger Phase 4.
#   Removed "imports a new appliance model with correct device_type" test —
#   device_type: :appliance no longer exists; the enum value was removed in
#   Session 41. Peripheral import (device_type: :peripheral) is already
#   covered by the existing peripheral test below.
# v1.1 (Session 29): Added peripheral import test.
# v1.0 (Session 24): New test file — ComputerModelImportService.

require "test_helper"
require "csv"

class ComputerModelImportServiceTest < ActiveSupport::TestCase
  # ── Happy path — computer ──────────────────────────────────────────────────

  test "imports a new computer model and returns success with count" do
    result = process_csv("name\nPDP-11/44\n", device_type: :computer)

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert_equal 1, result[:count]

    model = ComputerModel.find_by!(name: "PDP-11/44")
    assert model.device_type_computer?
  end

  test "imports multiple new computer models" do
    csv_content = "name\nPDP-11/34\nPDP-11/23\n"
    result = process_csv(csv_content, device_type: :computer)

    assert result[:success]
    assert_equal 2, result[:count]
  end

  # ── Happy path — peripheral ────────────────────────────────────────────────

  test "imports a new peripheral model with correct device_type" do
    result = process_csv("name\nLA120\n", device_type: :peripheral)

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert_equal 1, result[:count]

    model = ComputerModel.find_by!(name: "LA120")
    assert model.device_type_peripheral?, "Imported model must have device_type: peripheral"
  end

  # ── Duplicate handling ─────────────────────────────────────────────────────

  test "silently skips existing model and returns count 0" do
    result = process_csv("name\nPDP-11/70\n", device_type: :computer)

    assert result[:success], "Skip should not be an error"
    assert_equal 0, result[:count]
    assert_equal 1, ComputerModel.where(name: "PDP-11/70").count
  end

  test "imports new records and skips existing ones in the same file" do
    csv_content = "name\nPDP-11/70\nPDP-11/44\n"
    result = process_csv(csv_content, device_type: :computer)

    assert result[:success]
    assert_equal 1, result[:count]
  end

  # ── Validation errors ─────────────────────────────────────────────────────

  test "returns error when name column is missing" do
    result = process_csv("model_name\nPDP-11/44\n")

    assert_not result[:success]
    assert_match "Missing required CSV columns", result[:error]
    assert_match "name",                         result[:error]
  end

  # ── File validation ────────────────────────────────────────────────────────

  test "returns error when file is nil" do
    result = ComputerModelImportService.process(nil, device_type: :computer)

    assert_not result[:success]
    assert_match "No file provided", result[:error]
  end

  test "returns error for non-CSV file" do
    result = process_csv("name\nPDP-11/44\n",
                          content_type: "application/octet-stream",
                          filename: "data.txt")

    assert_not result[:success]
    assert_match "CSV", result[:error]
  end

  private

  def process_csv(content, device_type: :computer,
                            content_type: "text/csv",
                            filename: "test_import.csv")
    tempfile = Tempfile.new(["cm_import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind
    tempfile.close

    upload = Rack::Test::UploadedFile.new(tempfile.path, content_type, false,
                                           original_filename: filename)

    ComputerModelImportService.process(upload, device_type: device_type)
  end
end
