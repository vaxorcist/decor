# decor/test/services/owner_import_service_test.rb
# version 1.5
# v1.5 (Session 41): Appliances → Peripherals merger Phase 4.
#   Rewrote two appliance import tests — "appliance" CSV value is now a
#   legacy alias that maps to :peripheral on import (backward compat):
#     "importing an 'appliance' row creates a computer with device_type peripheral"
#       — was device_type_appliance?; now device_type_peripheral? + peripheral_count
#     "'appliance' record_type is not treated as unknown"
#       — still passes; appliance→peripheral is silently accepted
#   Removed :appliance_count from result hash assertions (key no longer returned).
# v1.4 (Session 37): Comment rows; sentinel; pass 3 connections tests.
# v1.3 (Session 28): Separate per-device-type counters.
# v1.2 (Session 28): Peripheral record_type tests.
# v1.1 (Session 16): Appliance record_type tests.

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
    assert_equal "PDP-11/70",           computer.computer_model.name
    assert_equal "NEW-ORD-001",         computer.order_number
    assert_equal "Completely original", computer.computer_condition.name
    assert_equal "Working",             computer.run_status.name
    assert_equal "Some history",        computer.history
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
    assert_nil component.computer
    assert_equal "Memory Board", component.component_type.name
    assert_equal "Working",      component.component_condition.condition
    assert_equal "MB-ORD-01",    component.order_number
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

  # ── device_type: appliance (legacy backward compatibility) ────────────────
  #
  # CSV record_type "appliance" is a legacy value from before the Session 41
  # appliance→peripheral merger. OwnerImportService v1.5 maps it to :peripheral
  # so that old CSVs remain importable. The imported record has device_type: peripheral.

  test "importing an 'appliance' row creates a computer with device_type peripheral" do
    # "appliance" in the CSV is the legacy alias — it imports as peripheral.
    csv = build_csv([
      ["appliance", "HSC50", "APP-ORD-001", "APP-SN-001",
       nil, nil, "Storage controller",
       nil, nil, nil, nil, nil]
    ])

    assert_difference "@alice.computers.count", 1 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success], "Expected success, got: #{result[:error]}"
      # Legacy appliance rows now increment peripheral_count
      assert_equal 1, result[:peripheral_count]
      assert_equal 0, result[:computer_count]
    end

    # The record is stored as peripheral (device_type: 2), not appliance
    peripheral = @alice.computers.find_by!(serial_number: "APP-SN-001")
    assert peripheral.device_type_peripheral?,
           "Legacy 'appliance' CSV row must import as peripheral (device_type: 2)"
    assert_equal "HSC50",              peripheral.computer_model.name
    assert_equal "Storage controller", peripheral.history
  end

  test "'appliance' record_type is not treated as unknown" do
    # Backward compat: "appliance" is silently mapped to peripheral, not rejected.
    csv = build_csv([
      ["appliance", "HSC50", nil, "APP-SN-VALID", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Expected 'appliance' to be valid (legacy alias), got: #{result[:error]}"
  end

  # ── device_type: peripheral ───────────────────────────────────────────────

  test "importing a 'peripheral' row creates a computer with device_type peripheral" do
    csv = build_csv([
      ["peripheral", "DEC VT278", "PER-ORD-001", "PER-SN-001",
       nil, nil, "VT278 graphics terminal",
       nil, nil, nil, nil, nil]
    ])

    assert_difference "@alice.computers.count", 1 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success], "Expected success, got: #{result[:error]}"
      assert_equal 1, result[:peripheral_count]
      assert_equal 0, result[:computer_count]
    end

    peripheral = @alice.computers.find_by!(serial_number: "PER-SN-001")
    assert peripheral.device_type_peripheral?
    assert_equal "DEC VT278",             peripheral.computer_model.name
    assert_equal "VT278 graphics terminal", peripheral.history
  end

  test "'peripheral' record_type is not treated as unknown" do
    csv = build_csv([
      ["peripheral", "DEC VT278", nil, "PER-SN-VALID", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Expected 'peripheral' to be valid, got: #{result[:error]}"
  end

  test "importing a 'computer' row still creates device_type: computer" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "COMPUTER-TYPE-SN", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])
    OwnerImportService.process(@alice, csv_upload(csv))

    computer = @alice.computers.find_by!(serial_number: "COMPUTER-TYPE-SN")
    assert computer.device_type_computer?
  end

  # ── Two-pass strategy ────────────────────────────────────────────────────

  test "component row can reference a computer created in the same import" do
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
    assert_equal computer, component.computer
  end

  test "component rows before computer rows in CSV still attach correctly" do
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
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "SN12345", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    assert_no_difference "@alice.computers.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success]
      assert_equal 0, result[:computer_count]
    end
  end

  test "same serial number on a different model is NOT a duplicate and is imported" do
    csv = build_csv([
      ["computer", "VT100", nil, "SN12345", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    assert_difference "@alice.computers.count", 1 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success], "Same serial on different model must succeed: #{result[:error]}"
      assert_equal 1, result[:computer_count]
    end
  end

  test "re-importing an existing component serial number is silently skipped" do
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

    assert_equal "Original", existing.reload.description
  end

  test "component without serial number is always created (no duplicate check)" do
    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil, "CPU Board", nil, nil, nil, "No serial 1"],
      ["component", nil, nil, nil, nil, nil, nil, "CPU Board", nil, nil, nil, "No serial 2"]
    ])

    assert_difference "@alice.components.count", 2 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success]
      assert_equal 2, result[:component_count]
    end
  end

  # ── Unknown computer serial in component → spare ─────────────────────────

  test "component with unknown computer_serial_number is imported as spare" do
    csv = build_csv([
      ["component", nil, nil, "UNKNOWN-SERIAL-XYZ", nil, nil, nil,
       "Memory Board", nil, "SPARE-DOWNGRADE-SN", nil, "Should become spare"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success]

    component = @alice.components.find_by!(serial_number: "SPARE-DOWNGRADE-SN")
    assert_nil component.computer
  end

  # ── Comment row handling ─────────────────────────────────────────────────

  test "comment rows (record_type starting with '#') are silently skipped" do
    csv = build_csv([
      ["# This is a comment — ignore me"],
      ["computer", "PDP-11/70", nil, "COMMENT-SKIP-SN", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Comment row must not cause failure: #{result[:error]}"
    assert @alice.computers.exists?(serial_number: "COMMENT-SKIP-SN"),
           "Computer after comment row must be imported"
  end

  test "comment rows do not count as unknown record_type" do
    csv = build_csv([
      ["# Owner: alice — exported 2026-03-20"],
      ["# Another annotation line"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Comment-only CSV must succeed: #{result[:error]}"
  end

  test "comment row does not count toward any import counter" do
    csv = build_csv([
      ["# Annotation only"]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success]
    assert_equal 0, result[:computer_count]
    assert_equal 0, result[:component_count]
    assert_equal 0, result[:connection_group_count].to_i
  end

  # ── Connections import ──────────────────────────────────────────────────

  test "CSV without a connections section imports normally with zero connection_group_count" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, "CONN-NOCONN-SN", nil, nil, nil,
       nil, nil, nil, nil, nil]
    ])
    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success]
    assert_equal 0, result[:connection_group_count].to_i
  end

  test "importing a connections section creates connection groups" do
    csv = build_csv_with_connections([], [
      { type: "RS-232 Serial", label: "My RS-232 link",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    assert_difference "ConnectionGroup.count", 1 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success], "Expected success, got: #{result[:error]}"
      assert_equal 1, result[:connection_group_count]
    end
  end

  test "imported connection group has the correct connection_type" do
    csv = build_csv_with_connections([], [
      { type: "RS-232 Serial", label: "Type test group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    OwnerImportService.process(@alice, csv_upload(csv))

    group = @alice.connection_groups.find_by(label: "Type test group")
    assert_not_nil group
    assert_equal "RS-232 Serial", group.connection_type.name
  end

  test "imported connection group with no type imports successfully with nil type" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "No type group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Group with no type must import successfully: #{result[:error]}"

    group = @alice.connection_groups.find_by(label: "No type group")
    assert_nil group.connection_type
  end

  test "imported connection group has the correct label" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "My special label",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    OwnerImportService.process(@alice, csv_upload(csv))
    assert @alice.connection_groups.exists?(label: "My special label")
  end

  test "imported connection group has the correct members" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "Member check group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    OwnerImportService.process(@alice, csv_upload(csv))

    group = @alice.connection_groups.find_by(label: "Member check group")
    assert_equal 2, group.connection_members.count
    member_serials = group.computers.pluck(:serial_number)
    assert_includes member_serials, "SN12345"
    assert_includes member_serials, "VAX-780-001"
  end

  test "connection group members can reference computers created in the same import" do
    csv = build_csv_with_connections(
      [
        ["computer", "PDP-11/70",  nil, "CONN-NEW-1", nil, nil, nil, nil, nil, nil, nil, nil],
        ["computer", "VAX-11/780", nil, "CONN-NEW-2", nil, nil, nil, nil, nil, nil, nil, nil]
      ],
      [
        { type: nil, label: "New computers group",
          members: [
            { model: "PDP-11/70",  serial: "CONN-NEW-1" },
            { model: "VAX-11/780", serial: "CONN-NEW-2" }
          ] }
      ]
    )

    result = OwnerImportService.process(@alice, csv_upload(csv))
    assert result[:success], "Expected success, got: #{result[:error]}"
    assert_equal 1, result[:connection_group_count]

    group = @alice.connection_groups.find_by(label: "New computers group")
    assert_not_nil group
    assert_equal 2, group.connection_members.count
  end

  test "multiple connection groups in one file are all imported" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "First group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] },
      { type: nil, label: "Second group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    assert_difference "ConnectionGroup.count", 2 do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      assert result[:success], "Expected success, got: #{result[:error]}"
      assert_equal 2, result[:connection_group_count]
    end
  end

  test "unknown connection_type name fails with descriptive error" do
    csv = build_csv_with_connections([], [
      { type: "Nonexistent Bus Type", label: "Bad type group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "Nonexistent Bus Type", result[:error]
  end

  test "connection_member referencing a non-existent computer fails" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "Bad member group",
        members: [
          { model: "PDP-11/70", serial: "DOES-NOT-EXIST-999" },
          { model: "PDP-11/70", serial: "SN12345" }
        ] }
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "DOES-NOT-EXIST-999", result[:error]
  end

  test "connection group with fewer than 2 members fails model validation" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "Too small group",
        members: [
          { model: "PDP-11/70", serial: "SN12345" }
        ] }
    ])

    assert_no_difference "ConnectionGroup.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      refute result[:success],
             "Group with only 1 member must fail minimum_two_members validation"
    end
  end

  test "connection group with 0 members fails model validation" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "Empty group", members: [] }
    ])

    assert_no_difference "ConnectionGroup.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      refute result[:success]
    end
  end

  test "connection_member before any connection_group row fails with descriptive error" do
    csv = CSV.generate(headers: true, force_quotes: true) do |c|
      c << OwnerExportService::CSV_HEADERS
      c << ["! --- connections ---"]
      c << ["connection_member", "PDP-11/70", nil, "SN12345",
            nil, nil, nil, nil, nil, nil, nil, nil]
    end

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "connection_member", result[:error]
  end

  test "connection_group row before the sentinel is treated as unknown record_type" do
    csv = build_csv([
      ["connection_group", "RS-232 Serial", "My link",
       nil, nil, nil, nil, nil, nil, nil, nil, nil]
    ])

    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "connection_group", result[:error]
  end

  test "bad connection group does not prevent earlier successful connection groups" do
    csv = build_csv_with_connections([], [
      { type: nil, label: "Valid group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] },
      { type: nil, label: "Invalid group (1 member)",
        members: [
          { model: "PDP-11/70", serial: "SN12345" }
        ] }
    ])

    assert_no_difference "ConnectionGroup.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      refute result[:success]
    end
  end

  # ── Atomicity ────────────────────────────────────────────────────────────

  test "single bad row rolls back the entire import" do
    csv = build_csv([
      ["computer", "PDP-11/70",       nil, "ATOMIC-GOOD-1", nil, nil, nil, nil, nil, nil, nil, nil],
      ["computer", "NONEXISTENT MODEL", nil, "ATOMIC-BAD-1",  nil, nil, nil, nil, nil, nil, nil, nil],
      ["computer", "PDP-11/70",       nil, "ATOMIC-GOOD-2", nil, nil, nil, nil, nil, nil, nil, nil]
    ])

    assert_no_difference "@alice.computers.count" do
      result = OwnerImportService.process(@alice, csv_upload(csv))
      refute result[:success]
      assert_match "NONEXISTENT MODEL", result[:error]
    end

    refute @alice.computers.exists?(serial_number: "ATOMIC-GOOD-1")
    refute @alice.computers.exists?(serial_number: "ATOMIC-GOOD-2")
  end

  # ── Required field validation ─────────────────────────────────────────────

  test "computer row without serial_number fails with descriptive error" do
    csv = build_csv([
      ["computer", "PDP-11/70", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
    ])
    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "computer_serial_number", result[:error]
  end

  test "computer row without computer_model fails with descriptive error" do
    csv = build_csv([
      ["computer", nil, nil, "NO-MODEL-SN", nil, nil, nil, nil, nil, nil, nil, nil]
    ])
    result = OwnerImportService.process(@alice, csv_upload(csv))
    refute result[:success]
    assert_match "computer_model", result[:error]
  end

  test "component row without component_type fails with descriptive error" do
    csv = build_csv([
      ["component", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "No type given"]
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
    result  = OwnerImportService.process(@alice, csv_upload(bad_csv))
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

  def build_csv(rows)
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      rows.each { |row| csv << row }
    end
  end

  def build_csv_with_connections(device_rows, connection_groups_data)
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      device_rows.each { |row| csv << row }
      csv << ["! --- connections ---"]
      connection_groups_data.each do |g|
        csv << ["connection_group", g[:type], g[:label],
                nil, nil, nil, nil, nil, nil, nil, nil, nil]
        g[:members].each do |m|
          csv << ["connection_member", m[:model], nil, m[:serial],
                  nil, nil, nil, nil, nil, nil, nil, nil]
        end
      end
    end
  end

  def csv_upload(content, filename: "test_import.csv", content_type: "text/csv")
    tempfile = Tempfile.new(["import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: filename,
      type:     content_type,
      head:     "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\""
    )
  end
end
