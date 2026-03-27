# decor/test/services/owner_export_service_test.rb
# version 1.4
# v1.4 (Session 41): Appliances → Peripherals merger Phase 4.
#   Removed appliance record_type tests — OwnerExportService v1.4 no longer
#   includes appliance in DEVICE_TYPE_EXPORT_ORDER.
#   Rewrote "in a mixed export" ordering test: now verifies computers appear before
#   peripherals (two device types; appliance creation removed).
#   Updated fixture baseline comment: dec_unibus_router is now peripheral.
# v1.3 (Session 37): Ordered export; comment header; connections section tests.
# v1.2 (Session 28): Peripheral record_type tests.
# v1.1 (Session 16): Appliance record_type tests.
#
# Fixture baseline (alice = owners(:one)):
#   Computers:  alice_pdp11 (SN12345, PDP-11/70, device_type: 0)
#               alice_vax   (VAX-780-001, VAX-11/780, device_type: 0)
#               unassigned_condition_test (TEST-001, PDP-11/70, device_type: 0)
#   Components: pdp11_memory, pdp11_cpu (attached to alice_pdp11), spare_disk (spare)
#   Connections: alice_pdp11_vax group (no type, label "Lab setup",
#                  members: alice_pdp11 SN12345 + alice_vax VAX-780-001)
#
# Fixture baseline (charlie = owners(:three)):
#   dec_unibus_router  (RTR-001, PDP-11/70, device_type: 2 = peripheral)
#   charlie_dec_vt278  (VT278-001, VT100 model, device_type: 2 = peripheral)
#   No connection groups.

require "test_helper"
require "csv"

class OwnerExportServiceTest < ActiveSupport::TestCase
  setup do
    @alice      = owners(:one)
    @csv_string = OwnerExportService.export(@alice)
    @csv        = CSV.parse(@csv_string, headers: true)
  end

  # ── Headers ─────────────────────────────────────────────────────────────────

  test "CSV has the correct headers" do
    assert_equal OwnerExportService::CSV_HEADERS, @csv.headers
  end

  # ── Row counts (data-derived) ────────────────────────────────────────────────

  test "device row count equals owner's computer count" do
    device_types    = %w[computer peripheral]
    device_row_count = @csv.count { |r| device_types.include?(r["record_type"]) }
    assert_equal @alice.computers.count, device_row_count
  end

  test "component row count equals owner's component count" do
    component_row_count = @csv.count { |r| r["record_type"] == "component" }
    assert_equal @alice.components.count, component_row_count
  end

  test "total row count accounts for comment, devices, components, sentinel, and connections" do
    comment_rows  = 1
    device_count  = @alice.computers.count
    comp_count    = @alice.components.count
    group_count   = @alice.connection_groups.count
    member_count  = ConnectionMember.joins(:connection_group)
                                    .where(connection_groups: { owner: @alice })
                                    .count
    sentinel_count = group_count > 0 ? 1 : 0

    expected = comment_rows + device_count + comp_count +
               sentinel_count + group_count + member_count

    assert_equal expected, @csv.size
  end

  test "exports correct number of computer rows" do
    # alice's three computers are all device_type: 0 = computer
    computer_rows = @csv.select { |row| row["record_type"] == "computer" }
    assert_equal 3, computer_rows.size
  end

  test "exports correct number of component rows" do
    component_rows = @csv.select { |row| row["record_type"] == "component" }
    assert_equal 3, component_rows.size
  end

  # ── Comment header ───────────────────────────────────────────────────────────

  test "first data row is a comment row whose record_type starts with '#'" do
    first = @csv.first
    assert first["record_type"]&.start_with?("#"),
           "First data row must be a comment (record_type starting with '#')"
  end

  test "comment row contains the owner's user_name" do
    assert_match @alice.user_name, @csv.first["record_type"]
  end

  test "comment row contains today's date" do
    assert_match Date.today.to_s, @csv.first["record_type"]
  end

  # ── Ordered export: Computers → Peripherals ──────────────────────────────────

  test "in a mixed export, all computers appear before all peripherals" do
    # Build an owner with one computer and one peripheral to verify ordering.
    owner = Owner.create!(user_name: "sorttest1", email: "st1@example.com",
                          password: "ValidTest2026!")
    owner.computers.create!(serial_number: "SORT-COMP-01",
                            computer_model: computer_models(:pdp11_70),
                            device_type: :computer)
    owner.computers.create!(serial_number: "SORT-PERI-01",
                            computer_model: computer_models(:dec_vt278),
                            device_type: :peripheral)

    csv        = CSV.parse(OwnerExportService.export(owner), headers: true)
    rows       = csv.reject { |r| r["record_type"].to_s.start_with?("#") }
    rec_types  = rows.map { |r| r["record_type"] }

    computer_idx   = rec_types.index("computer")
    peripheral_idx = rec_types.index("peripheral")

    assert_not_nil computer_idx,   "Expected a computer row"
    assert_not_nil peripheral_idx, "Expected a peripheral row"

    assert computer_idx < peripheral_idx,
           "All computers must appear before peripherals"
  end

  test "all device rows (all types) appear before any component row" do
    device_types = %w[computer peripheral]
    rows = @csv.reject { |r| r["record_type"].to_s.start_with?("#") }
    row_types = rows.map { |r| r["record_type"] }

    last_device_idx     = row_types.rindex { |t| device_types.include?(t) }
    first_component_idx = row_types.index("component")

    if last_device_idx && first_component_idx
      assert last_device_idx < first_component_idx,
             "All device rows must precede all component rows"
    end
  end

  test "within each device type, rows are sorted by model name then serial number" do
    # Alice has two PDP-11/70s: SN12345 and TEST-001. PDP-11/70 < VAX-11/780 alphabetically.
    computer_rows = @csv.select { |r| r["record_type"] == "computer" }

    serials = computer_rows.map { |r| r["computer_serial_number"] }
    models  = computer_rows.map { |r| r["computer_model"] }

    last_pdp_idx  = models.rindex("PDP-11/70")
    first_vax_idx = models.index("VAX-11/780")

    if last_pdp_idx && first_vax_idx
      assert last_pdp_idx < first_vax_idx,
             "PDP-11/70 rows must come before VAX-11/780 rows within computers"
    end
  end

  # ── device_type / record_type mapping ───────────────────────────────────────

  test "computer (device_type: 0) exports with record_type 'computer'" do
    peripheral_rows = @csv.select { |r| r["record_type"] == "peripheral" }
    assert_empty peripheral_rows, "No peripheral rows expected in alice's export"
  end

  # ── Peripheral record_type mapping ──────────────────────────────────────────

  test "peripheral (device_type: 2) exports with record_type 'peripheral'" do
    owner = Owner.create!(user_name: "periphexp01", email: "periphexp01@example.com",
                          password: "ValidTest2026!")
    owner.computers.create!(serial_number: "VT278-EXP-001",
                            computer_model: computer_models(:dec_vt278),
                            device_type: :peripheral)

    csv            = CSV.parse(OwnerExportService.export(owner), headers: true)
    peripheral_rows = csv.select { |r| r["record_type"] == "peripheral" }

    assert_equal 1, peripheral_rows.size
    assert_equal "VT278-EXP-001", peripheral_rows.first["computer_serial_number"]
  end

  test "peripheral row carries correct model name" do
    owner = Owner.create!(user_name: "periphexp02", email: "periphexp02@example.com",
                          password: "ValidTest2026!")
    owner.computers.create!(serial_number: "VT278-EXP-002",
                            computer_model: computer_models(:dec_vt278),
                            device_type: :peripheral)

    csv = CSV.parse(OwnerExportService.export(owner), headers: true)
    row = csv.find { |r| r["record_type"] == "peripheral" }
    assert_equal "DEC VT278", row["computer_model"]
  end

  test "peripheral row has blank component columns" do
    owner = Owner.create!(user_name: "periphexp03", email: "periphexp03@example.com",
                          password: "ValidTest2026!")
    owner.computers.create!(serial_number: "VT278-EXP-003",
                            computer_model: computer_models(:dec_vt278),
                            device_type: :peripheral)

    csv = CSV.parse(OwnerExportService.export(owner), headers: true)
    row = csv.find { |r| r["record_type"] == "peripheral" }
    assert_nil row["component_type"].presence
    assert_nil row["component_description"].presence
    assert_nil row["component_serial_number"].presence
    assert_nil row["component_order_number"].presence
    assert_nil row["component_condition"].presence
  end

  test "peripheral (device_type: 2) does NOT export with record_type 'computer'" do
    owner = Owner.create!(user_name: "periphexp04", email: "periphexp04@example.com",
                          password: "ValidTest2026!")
    owner.computers.create!(serial_number: "VT278-EXP-004",
                            computer_model: computer_models(:dec_vt278),
                            device_type: :peripheral)

    csv          = CSV.parse(OwnerExportService.export(owner), headers: true)
    computer_rows = csv.select { |r| r["record_type"] == "computer" }
    assert_empty computer_rows, "A peripheral must not export with record_type 'computer'"
  end

  # ── dec_unibus_router is now peripheral (Session 41 merger) ─────────────────

  test "dec_unibus_router (formerly appliance, now peripheral) exports with record_type 'peripheral'" do
    # dec_unibus_router was device_type: 1 (appliance) before Session 41.
    # It is now device_type: 2 (peripheral) after the merger.
    charlie       = owners(:three)
    csv           = CSV.parse(OwnerExportService.export(charlie), headers: true)
    peripheral_rows = csv.select { |r| r["record_type"] == "peripheral" }

    # Charlie has two peripherals: dec_unibus_router and charlie_dec_vt278
    assert peripheral_rows.any? { |r| r["computer_serial_number"] == "RTR-001" },
           "dec_unibus_router (RTR-001) must appear as a peripheral row"
  end

  test "dec_unibus_router row has blank component columns" do
    charlie = owners(:three)
    csv     = CSV.parse(OwnerExportService.export(charlie), headers: true)
    row     = csv.find { |r| r["record_type"] == "peripheral" &&
                              r["computer_serial_number"] == "RTR-001" }
    assert_not_nil row, "Expected a peripheral row for RTR-001"
    assert_nil row["component_type"].presence
    assert_nil row["component_description"].presence
  end

  # ── Computer row content ─────────────────────────────────────────────────────

  test "computer row has correct record_type" do
    assert_equal "computer", find_computer_row("SN12345")["record_type"]
  end

  test "computer row has correct model name" do
    assert_equal "PDP-11/70", find_computer_row("SN12345")["computer_model"]
  end

  test "computer row has correct serial number" do
    assert_equal "SN12345", find_computer_row("SN12345")["computer_serial_number"]
  end

  test "computer row has correct order number" do
    assert_equal "ORD-1985-001", find_computer_row("SN12345")["computer_order_number"]
  end

  test "computer row has correct condition" do
    assert_equal "Completely original", find_computer_row("SN12345")["computer_condition"]
  end

  test "computer row has correct run status" do
    assert_equal "Working", find_computer_row("SN12345")["computer_run_status"]
  end

  test "computer row has correct history" do
    assert_equal "Originally used at MIT for student labs.",
                 find_computer_row("SN12345")["computer_history"]
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
    assert_nil find_computer_row("VAX-780-001")["computer_history"].presence
  end

  # ── Component row content ─────────────────────────────────────────────────

  test "component row has correct record_type" do
    assert_equal "component", find_component_row("Memory Board")["record_type"]
  end

  test "component row has correct component type" do
    assert_equal "CPU Board", find_component_row("CPU Board")["component_type"]
  end

  test "component row has correct description" do
    assert_equal "Original 256KB core memory board",
                 find_component_row("Memory Board")["component_description"]
  end

  test "attached component row carries parent computer serial number as FK" do
    assert_equal "SN12345", find_component_row("Memory Board")["computer_serial_number"]
  end

  test "spare component row has blank computer_serial_number" do
    assert_nil find_component_row("Disk Drive")["computer_serial_number"].presence
  end

  test "spare component row has blank computer model and condition columns" do
    row = find_component_row("Disk Drive")
    assert_nil row["computer_model"].presence
    assert_nil row["computer_condition"].presence
    assert_nil row["computer_run_status"].presence
  end

  # ── Connections export ───────────────────────────────────────────────────────

  test "sentinel row is present when owner has connection groups" do
    sentinel_rows = @csv.select { |r| r["record_type"]&.start_with?("!") }
    assert_equal 1, sentinel_rows.size,
                 "Exactly one sentinel row expected when owner has connections"
  end

  test "sentinel row value starts with '!'" do
    sentinel = @csv.find { |r| r["record_type"]&.start_with?("!") }
    assert_not_nil sentinel
    assert sentinel["record_type"].start_with?("!")
  end

  test "connection_group rows appear after the sentinel" do
    rows          = @csv.map { |r| r }
    sentinel_idx  = rows.index { |r| r["record_type"]&.start_with?("!") }
    assert_not_nil sentinel_idx

    conn_group_before_sentinel = rows[0...sentinel_idx].any? { |r| r["record_type"] == "connection_group" }
    assert_not conn_group_before_sentinel,
               "connection_group rows must not appear before the sentinel"

    conn_groups_after = rows[(sentinel_idx + 1)..].count { |r| r["record_type"] == "connection_group" }
    assert_equal @alice.connection_groups.count, conn_groups_after
  end

  test "connection_group row with no connection_type has blank computer_model column" do
    group_row = @csv.find { |r| r["record_type"] == "connection_group" }
    assert_not_nil group_row
    assert_nil group_row["computer_model"].presence,
               "connection_group with no type should have blank computer_model column"
  end

  test "connection_group row carries the group label in computer_order_number column" do
    group_row = @csv.find { |r| r["record_type"] == "connection_group" }
    assert_equal "Lab setup", group_row["computer_order_number"]
  end

  test "connection_member rows follow their group and carry model + serial" do
    member_rows = @csv.select { |r| r["record_type"] == "connection_member" }
    serials     = member_rows.map { |r| r["computer_serial_number"] }
    models      = member_rows.map { |r| r["computer_model"] }

    assert_includes serials, "SN12345",      "alice_pdp11 serial must appear in member rows"
    assert_includes serials, "VAX-780-001",  "alice_vax serial must appear in member rows"
    assert_includes models,  "PDP-11/70"
    assert_includes models,  "VAX-11/780"
  end

  test "connection_member rows appear after the sentinel" do
    rows         = @csv.map { |r| r }
    sentinel_idx = rows.index { |r| r["record_type"]&.start_with?("!") }
    assert_not_nil sentinel_idx

    member_before = rows[0...sentinel_idx].any? { |r| r["record_type"] == "connection_member" }
    assert_not member_before, "connection_member rows must not appear before the sentinel"
  end

  test "connection_group row has blank component columns" do
    group_row = @csv.find { |r| r["record_type"] == "connection_group" }
    assert_nil group_row["component_type"].presence
    assert_nil group_row["component_serial_number"].presence
  end

  test "connection_member row has blank component columns" do
    member_row = @csv.find { |r| r["record_type"] == "connection_member" }
    assert_nil member_row["component_type"].presence
    assert_nil member_row["component_serial_number"].presence
  end

  test "connection group with a connection_type exports the type name in computer_model column" do
    owner = Owner.create!(user_name: "cgtypetest", email: "cgt@example.com",
                          password: "ValidTest2026!")
    c1 = owner.computers.create!(serial_number: "CGT-001",
                                  computer_model: computer_models(:pdp11_70),
                                  device_type: :computer)
    c2 = owner.computers.create!(serial_number: "CGT-002",
                                  computer_model: computer_models(:vax11_780),
                                  device_type: :computer)
    group = owner.connection_groups.build(connection_type: connection_types(:rs232),
                                            label: "RS232 test")
    group.connection_members.build(computer: c1)
    group.connection_members.build(computer: c2)
    group.save!

    csv       = CSV.parse(OwnerExportService.export(owner), headers: true)
    group_row = csv.find { |r| r["record_type"] == "connection_group" }
    assert_equal "RS-232 Serial", group_row["computer_model"],
                 "connection_type name must appear in the computer_model column"
  end

  test "no sentinel row when owner has no connection groups" do
    empty_owner = Owner.create!(user_name: "noconns01", email: "nc1@example.com",
                                password: "ValidTest2026!")
    csv          = CSV.parse(OwnerExportService.export(empty_owner), headers: true)
    sentinel_rows = csv.select { |r| r["record_type"]&.start_with?("!") }
    assert_empty sentinel_rows,
                 "No sentinel row expected when owner has no connection groups"
  end

  # ── Owner isolation ────────────────────────────────────────────────────────

  test "export contains only the given owner's records" do
    serials = @csv.select { |r| r["record_type"] == "computer" }
                  .map    { |r| r["computer_serial_number"] }
    refute_includes serials, "PDP8-7891"
    refute_includes serials, "VT100-5432"
  end

  # ── Edge case: owner with no records ─────────────────────────────────────

  test "export for owner with no records returns only headers and a comment row" do
    empty_owner = Owner.create!(user_name: "emptyowner2", email: "empty2@example.com",
                                password: "ValidTest2026!")
    csv = CSV.parse(OwnerExportService.export(empty_owner), headers: true)
    assert_equal 1, csv.size
    assert_equal OwnerExportService::CSV_HEADERS, csv.headers
    assert csv.first["record_type"].start_with?("#"), "Only row must be the comment header"
  end

  private

  def find_computer_row(serial_number)
    @csv.find { |r| r["record_type"] == "computer" && r["computer_serial_number"] == serial_number }
        .tap { |r| assert r, "Expected a computer row with serial '#{serial_number}'" }
  end

  def find_component_row(component_type)
    @csv.find { |r| r["record_type"] == "component" && r["component_type"] == component_type }
        .tap { |r| assert r, "Expected a component row with component_type '#{component_type}'" }
  end
end
