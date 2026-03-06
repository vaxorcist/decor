# decor/test/services/owner_export_service_test.rb - version 1.1
# Session 16: Added tests for device_type / record_type:
#   - Appliance (device_type: 1) exports with record_type "appliance"
#   - Computer (device_type: 0) still exports with record_type "computer"
#
# Tests for OwnerExportService — verifies CSV output structure and content.
#
# Fixture baseline (alice = owners(:one)):
#   Computers:  alice_pdp11 (SN12345, ORD-1985-001, PDP-11/70, original, working)
#               alice_vax   (VAX-780-001, ORD-VAX-002, VAX-11/780, original_repaired, repair)
#               unassigned_condition_test (TEST-001, ORD-TEST-001, PDP-11/70, built, defective)
#   Components: pdp11_memory (attached alice_pdp11, Memory Board, no serial/condition in fixture)
#               pdp11_cpu    (attached alice_pdp11, CPU Board,    no serial/condition in fixture)
#               spare_disk   (spare — no computer,  Disk Drive,   no serial/condition in fixture)
#
# Fixture baseline (charlie = owners(:three)):
#   Computers:  dec_unibus_router (RTR-001, ORD-RTR-001, PDP-11/70, original, working,
#               device_type: 1 = appliance)

require "test_helper"
require "csv"

class OwnerExportServiceTest < ActiveSupport::TestCase
  setup do
    @alice = owners(:one)
    @csv_string = OwnerExportService.export(@alice)
    @csv = CSV.parse(@csv_string, headers: true)
  end

  # ── Headers ─────────────────────────────────────────────────────────────────

  test "CSV has the correct headers" do
    assert_equal OwnerExportService::CSV_HEADERS, @csv.headers
  end

  # ── Row counts ──────────────────────────────────────────────────────────────

  test "exports correct number of computer rows" do
    # "computer" record_type only — alice's computers are all device_type: 0
    computer_rows = @csv.select { |row| row["record_type"] == "computer" }
    assert_equal 3, computer_rows.size
  end

  test "exports correct number of component rows" do
    component_rows = @csv.select { |row| row["record_type"] == "component" }
    # Alice has 3 components from fixtures
    assert_equal 3, component_rows.size
  end

  test "total row count is computers + components" do
    assert_equal @alice.computers.count + @alice.components.count, @csv.size
  end

  # ── device_type / record_type mapping ───────────────────────────────────────

  test "appliance (device_type: 1) exports with record_type 'appliance'" do
    # dec_unibus_router belongs to charlie (owners(:three)), device_type: 1
    charlie = owners(:three)
    csv = CSV.parse(OwnerExportService.export(charlie), headers: true)

    appliance_rows = csv.select { |row| row["record_type"] == "appliance" }
    assert_equal 1, appliance_rows.size, "Expected exactly one appliance row in charlie's export"
    assert_equal "RTR-001", appliance_rows.first["computer_serial_number"]
  end

  test "computer (device_type: 0) exports with record_type 'computer'" do
    # All of alice's computers are device_type: 0 — none should export as "appliance"
    appliance_rows = @csv.select { |row| row["record_type"] == "appliance" }
    assert_equal 0, appliance_rows.size, "No appliance rows expected in alice's export"
  end

  test "appliance row carries correct model name" do
    charlie = owners(:three)
    csv = CSV.parse(OwnerExportService.export(charlie), headers: true)

    appliance_row = csv.find { |row| row["record_type"] == "appliance" }
    assert_equal "PDP-11/70", appliance_row["computer_model"]
  end

  test "appliance row has blank component columns" do
    charlie = owners(:three)
    csv = CSV.parse(OwnerExportService.export(charlie), headers: true)

    appliance_row = csv.find { |row| row["record_type"] == "appliance" }
    assert_nil appliance_row["component_type"].presence
    assert_nil appliance_row["component_description"].presence
  end

  # ── Computer row content ─────────────────────────────────────────────────────

  test "computer row has correct record_type" do
    row = find_computer_row("SN12345")
    assert_equal "computer", row["record_type"]
  end

  test "computer row has correct model name" do
    row = find_computer_row("SN12345")
    assert_equal "PDP-11/70", row["computer_model"]
  end

  test "computer row has correct serial number" do
    row = find_computer_row("SN12345")
    assert_equal "SN12345", row["computer_serial_number"]
  end

  test "computer row has correct order number" do
    row = find_computer_row("SN12345")
    assert_equal "ORD-1985-001", row["computer_order_number"]
  end

  test "computer row has correct condition" do
    row = find_computer_row("SN12345")
    assert_equal "Completely original", row["computer_condition"]
  end

  test "computer row has correct run status" do
    row = find_computer_row("SN12345")
    assert_equal "Working", row["computer_run_status"]
  end

  test "computer row has correct history" do
    row = find_computer_row("SN12345")
    assert_equal "Originally used at MIT for student labs.", row["computer_history"]
  end

  test "computer row has blank component columns" do
    row = find_computer_row("SN12345")
    assert_nil row["component_type"].presence
    assert_nil row["component_description"].presence
    assert_nil row["component_serial_number"].presence
    assert_nil row["component_order_number"].presence
    assert_nil row["component_condition"].presence
  end

  test "computer with blank history exports blank history column" do
    row = find_computer_row("VAX-780-001")
    assert_nil row["computer_history"].presence
  end

  # ── Component row content ─────────────────────────────────────────────────

  test "component row has correct record_type" do
    row = find_component_row("Memory Board")
    assert_equal "component", row["record_type"]
  end

  test "component row has correct component type" do
    row = find_component_row("CPU Board")
    assert_equal "CPU Board", row["component_type"]
  end

  test "component row has correct description" do
    row = find_component_row("Memory Board")
    assert_equal "Original 256KB core memory board", row["component_description"]
  end

  test "attached component row carries parent computer serial number as FK" do
    # pdp11_memory is attached to alice_pdp11 (SN12345)
    row = find_component_row("Memory Board")
    assert_equal "SN12345", row["computer_serial_number"]
  end

  test "spare component row has blank computer_serial_number" do
    # spare_disk has no computer
    row = find_component_row("Disk Drive")
    assert_nil row["computer_serial_number"].presence
  end

  test "spare component row has blank computer model and condition columns" do
    row = find_component_row("Disk Drive")
    assert_nil row["computer_model"].presence
    assert_nil row["computer_condition"].presence
    assert_nil row["computer_run_status"].presence
  end

  # ── Owner isolation ────────────────────────────────────────────────────────

  test "export contains only the given owner's records" do
    # Bob's computers (bob_pdp8, bob_vt100) must not appear in Alice's export
    serial_numbers = @csv
      .select { |row| row["record_type"] == "computer" }
      .map { |row| row["computer_serial_number"] }

    refute_includes serial_numbers, "PDP8-7891",  "Bob's PDP-8 should not appear in Alice's export"
    refute_includes serial_numbers, "VT100-5432", "Bob's VT100 should not appear in Alice's export"
  end

  # ── Edge case: owner with no records ─────────────────────────────────────

  test "export for owner with no records returns only headers" do
    empty_owner = Owner.create!(
      user_name: "emptyowner",
      email: "empty@example.com",
      password: "ValidTest2026!"
    )
    csv = CSV.parse(OwnerExportService.export(empty_owner), headers: true)
    assert_equal 0, csv.size
    assert_equal OwnerExportService::CSV_HEADERS, csv.headers
  end

  private

  # Find the first computer row with the given serial number.
  def find_computer_row(serial_number)
    @csv.find { |row| row["record_type"] == "computer" && row["computer_serial_number"] == serial_number }.tap do |row|
      assert row, "Expected a computer row with serial_number '#{serial_number}'"
    end
  end

  # Find the first component row with the given component_type.
  def find_component_row(component_type)
    @csv.find { |row| row["record_type"] == "component" && row["component_type"] == component_type }.tap do |row|
      assert row, "Expected a component row with component_type '#{component_type}'"
    end
  end
end
