# decor/test/services/owner_import_service_test.rb
# version 1.7
# v1.7 (Session 49 — Session G): Updated for per-section CSV format and partial success.
#   build_csv / build_csv_with_connections / build_csv_with_software helpers rewritten
#     to produce the new per-section format (sentinels + section headers); no global
#     OwnerExportService::CSV_HEADERS row.
#   Row-level failure assertions updated: v1.8+ returns success: true + row_errors
#     for per-row validation failures (unknown model, missing serial, bad condition etc.).
#     Only file-level failures (bad file, connection_member before group) return success: false.
#   "Single bad row rolls back entire import" test removed — replaced by partial-success
#     test: good rows ARE saved when a bad row is present (v1.8 per-row independence).
#   Column name assertions updated: "serial_number is required" (not computer_serial_number),
#     "model is required" (not computer_model), "type is required" (not component_type).
#   Added tests:
#     - Partial success: good rows saved when a bad row is present
#     - row_errors returned correctly for failed rows
#     - barter_status imported for computers, peripherals, components
#     - component_category imported correctly; defaults to "integral" when absent
#     - installed_on_model used for component parent lookup (model+serial, not serial-only)
#     - owner_group_id duplicate detection: re-importing a connection group is skipped
#     - New-format CSV (sentinel-based) parsed correctly
#   Legacy format backward-compat test retained.
#
# v1.6 (Session 48): Software feature Session F — software_item import tests.
# v1.5 (Session 41): Appliances → Peripherals merger.

require "test_helper"
require "tempfile"

class OwnerImportServiceTest < ActiveSupport::TestCase
  setup do
    @alice = owners(:one)
    @bob   = owners(:two)
  end

  # ── Happy path — computers ───────────────────────────────────────────────

  test "imports a single computer row successfully" do
    assert_difference "@alice.computers.count", 1 do
      result = import(build_csv(computer_rows: [
        comp("computer", "PDP-11/70", "NEW-ORD-001", "IMPORT-SN-001",
             "Completely original", "Working", "Test history", "no_barter")
      ]))
      assert result[:success], result[:error]
      assert_equal 1, result[:computer_count]
    end
  end

  test "imported computer has correct attribute values" do
    import(build_csv(computer_rows: [
      comp("computer", "PDP-11/70", "NEW-ORD-001", "IMPORT-SN-002",
           "Completely original", "Working", "Some history", "offered")
    ]))
    c = @alice.computers.find_by!(serial_number: "IMPORT-SN-002")
    assert_equal "PDP-11/70",           c.computer_model.name
    assert_equal "NEW-ORD-001",         c.order_number
    assert_equal "Completely original", c.computer_condition.name
    assert_equal "Working",             c.run_status.name
    assert_equal "Some history",        c.history
    assert c.barter_status_offered?, "barter_status must be 'offered'"
  end

  test "barter_status defaults to no_barter when column is blank" do
    import(build_csv(computer_rows: [
      comp("computer", "PDP-11/70", nil, "BARTER-DEFAULT-SN")
    ]))
    c = @alice.computers.find_by!(serial_number: "BARTER-DEFAULT-SN")
    assert c.barter_status_no_barter?
  end

  test "barter_status wanted is imported correctly for peripherals" do
    import(build_csv(peripheral_rows: [
      comp("peripheral", "DEC VT278", nil, "BARTER-PERI-SN", nil, nil, nil, "wanted")
    ]))
    p = @alice.computers.find_by!(serial_number: "BARTER-PERI-SN")
    assert p.barter_status_wanted?
  end

  # ── Happy path — components ───────────────────────────────────────────────

  test "imports a spare component (no computer)" do
    assert_difference "@alice.components.count", 1 do
      result = import(build_csv(component_rows: [
        cmp(nil, nil, "Memory Board", "integral", "MB-ORD-01", "MB-SN-01", "Working",
            "Spare memory board", "no_barter")
      ]))
      assert result[:success], result[:error]
      assert_equal 1, result[:component_count]
    end
    c = @alice.components.find_by!(serial_number: "MB-SN-01")
    assert_nil c.computer
    assert_equal "Memory Board", c.component_type.name
  end

  test "component_category integral is imported correctly" do
    import(build_csv(component_rows: [
      cmp(nil, nil, "Memory Board", "integral", nil, "CAT-INT-SN", nil, nil, "no_barter")
    ]))
    assert @alice.components.find_by!(serial_number: "CAT-INT-SN").component_category_integral?
  end

  test "component_category peripheral is imported correctly" do
    import(build_csv(component_rows: [
      cmp(nil, nil, "Memory Board", "peripheral", nil, "CAT-PER-SN", nil, nil, "no_barter")
    ]))
    assert @alice.components.find_by!(serial_number: "CAT-PER-SN").component_category_peripheral?
  end

  test "component_category defaults to integral when column is blank" do
    import(build_csv(component_rows: [
      cmp(nil, nil, "Memory Board", nil, nil, "CAT-DEF-SN", nil, nil, nil)
    ]))
    assert @alice.components.find_by!(serial_number: "CAT-DEF-SN").component_category_integral?
  end

  test "barter_status defaults to no_barter for components when column is blank" do
    import(build_csv(component_rows: [
      cmp(nil, nil, "Memory Board", nil, nil, "BARTER-COMP-SN", nil, nil, nil)
    ]))
    assert @alice.components.find_by!(serial_number: "BARTER-COMP-SN").barter_status_no_barter?
  end

  test "component uses model+serial to attach to parent computer (not serial alone)" do
    # alice has SN12345 = PDP-11/70. Build a second owner with same serial on a different model.
    # Import a component with installed_on_model=PDP-11/70 — must attach to alice's PDP.
    import(build_csv(component_rows: [
      cmp("PDP-11/70", "SN12345", "Memory Board", "integral",
          nil, "MODEL-SERIAL-CMP-SN", nil, "Attached by model+serial", "no_barter")
    ]))
    component = @alice.components.find_by!(serial_number: "MODEL-SERIAL-CMP-SN")
    assert_equal "SN12345", component.computer.serial_number
    assert_equal "PDP-11/70", component.computer.computer_model.name
  end

  # ── Two-pass strategy ─────────────────────────────────────────────────────

  test "component can reference a computer created in the same import" do
    result = import(build_csv(
      computer_rows:  [comp("computer", "PDP-11/70", nil, "TWOPASS-SN")],
      component_rows: [cmp("PDP-11/70", "TWOPASS-SN", "Memory Board", "integral",
                           nil, nil, nil, "Attached to new computer", "no_barter")]
    ))
    assert result[:success], result[:error]
    computer  = @alice.computers.find_by!(serial_number: "TWOPASS-SN")
    component = @alice.components.find_by!(description: "Attached to new computer")
    assert_equal computer, component.computer
  end

  # ── Partial success ───────────────────────────────────────────────────────

  test "good rows are saved when a bad row is present (partial success)" do
    # v1.8+: each row is independent; good rows must not be rolled back.
    assert_difference "@alice.computers.count", 2 do
      result = import(build_csv(computer_rows: [
        comp("computer", "PDP-11/70",        nil, "PARTIAL-GOOD-1"),
        comp("computer", "NONEXISTENT MODEL", nil, "PARTIAL-BAD-1"),
        comp("computer", "PDP-11/70",        nil, "PARTIAL-GOOD-2")
      ]))
      assert result[:success], "Partial import must still return success: true"
      assert_equal 2, result[:computer_count]
      assert_equal 1, result[:row_errors].size
      assert_match "NONEXISTENT MODEL", result[:row_errors].first
    end
    assert @alice.computers.exists?(serial_number: "PARTIAL-GOOD-1")
    assert @alice.computers.exists?(serial_number: "PARTIAL-GOOD-2")
    refute @alice.computers.exists?(serial_number: "PARTIAL-BAD-1")
  end

  test "row_errors array contains one entry per failed row" do
    result = import(build_csv(computer_rows: [
      comp("computer", "NOPE-MODEL-1", nil, "ROW-ERR-1"),
      comp("computer", "NOPE-MODEL-2", nil, "ROW-ERR-2")
    ]))
    assert result[:success]
    assert_equal 2, result[:row_errors].size
  end

  # ── Appliance legacy alias ─────────────────────────────────────────────────

  test "appliance record_type imports as peripheral" do
    assert_difference "@alice.computers.count", 1 do
      result = import(build_csv(computer_rows: [
        comp("appliance", "HSC50", "APP-ORD-001", "APP-SN-001", nil, nil, "Storage controller")
      ]))
      assert result[:success], result[:error]
      assert_equal 1, result[:peripheral_count]
    end
    assert @alice.computers.find_by!(serial_number: "APP-SN-001").device_type_peripheral?
  end

  # ── Peripheral ────────────────────────────────────────────────────────────

  test "peripheral record_type creates device_type peripheral" do
    import(build_csv(peripheral_rows: [
      comp("peripheral", "DEC VT278", nil, "PER-SN-001")
    ]))
    assert @alice.computers.find_by!(serial_number: "PER-SN-001").device_type_peripheral?
  end

  test "computer record_type creates device_type computer" do
    import(build_csv(computer_rows: [
      comp("computer", "PDP-11/70", nil, "COMP-TYPE-SN")
    ]))
    assert @alice.computers.find_by!(serial_number: "COMP-TYPE-SN").device_type_computer?
  end

  # ── Duplicate skipping ────────────────────────────────────────────────────

  test "existing computer serial is silently skipped" do
    assert_no_difference "@alice.computers.count" do
      result = import(build_csv(computer_rows: [
        comp("computer", "PDP-11/70", nil, "SN12345")
      ]))
      assert result[:success]
      assert_equal 0, result[:computer_count]
    end
  end

  test "component with existing serial+type is silently skipped" do
    @alice.components.create!(component_type: component_types(:memory_board),
                               serial_number: "DUPE-COMP-SN", description: "Original")
    assert_no_difference "@alice.components.count" do
      result = import(build_csv(component_rows: [
        cmp(nil, nil, "Memory Board", "integral", nil, "DUPE-COMP-SN", nil, "Dupe attempt", "no_barter")
      ]))
      assert result[:success]
      assert_equal 0, result[:component_count]
    end
  end

  # ── Comment rows ──────────────────────────────────────────────────────────

  test "comment rows are silently skipped" do
    result = import(build_csv(
      comment_rows: ["# This is a comment"],
      computer_rows: [comp("computer", "PDP-11/70", nil, "COMMENT-SKIP-SN")]
    ))
    assert result[:success], result[:error]
    assert @alice.computers.exists?(serial_number: "COMMENT-SKIP-SN")
  end

  # ── Connections ───────────────────────────────────────────────────────────

  test "imports a connection group successfully" do
    assert_difference "ConnectionGroup.count", 1 do
      result = import(build_csv_with_connections([], [{
        owner_group_id: 99, type: "RS-232 Serial", label: "My link",
        members: [{ model: "PDP-11/70", serial: "SN12345" },
                  { model: "VAX-11/780", serial: "VAX-780-001" }]
      }]))
      assert result[:success], result[:error]
      assert_equal 1, result[:connection_group_count]
    end
  end

  test "re-importing an existing connection group is silently skipped (owner_group_id match)" do
    # alice already has alice_pdp11_vax — derive its owner_group_id from the fixture.
    existing = @alice.connection_groups.first
    assert_no_difference "ConnectionGroup.count" do
      result = import(build_csv_with_connections([], [{
        owner_group_id: existing.owner_group_id,
        type: nil, label: "Different label now",
        members: [{ model: "PDP-11/70",  serial: "SN12345" },
                  { model: "VAX-11/780", serial: "VAX-780-001" }]
      }]))
      assert result[:success], result[:error]
      assert_equal 0, result[:connection_group_count]
    end
  end

  test "connection group with a new member is NOT skipped when owner_group_id differs" do
    assert_difference "ConnectionGroup.count", 1 do
      # New owner_group_id → treated as a new group, not a duplicate.
      import(build_csv_with_connections([], [{
        owner_group_id: 999, type: nil, label: "Expanded group",
        members: [{ model: "PDP-11/70",  serial: "SN12345" },
                  { model: "VAX-11/780", serial: "VAX-780-001" }]
      }]))
    end
  end

  test "connection_member before any connection_group row fails" do
    csv = CSV.generate(force_quotes: true) do |c|
      c << ["# test"]
      c << ["! --- connections ---"]
      c << OwnerExportService::CONNECTION_SECTION_HEADERS
      c << ["connection_member", nil, "PDP-11/70", nil, "SN12345"]
    end
    result = import(csv)
    refute result[:success]
    assert_match "connection_member", result[:error]
  end

  test "unknown connection_type name is a row error (partial success)" do
    result = import(build_csv_with_connections([], [{
      owner_group_id: 88, type: "Nonexistent Bus", label: "bad",
      members: [{ model: "PDP-11/70", serial: "SN12345" },
                { model: "VAX-11/780", serial: "VAX-780-001" }]
    }]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "Nonexistent Bus", result[:row_errors].first
  end

  # ── Software import ───────────────────────────────────────────────────────

  test "software_item imports successfully" do
    sw_name = software_names(:tops20).name
    assert_difference "@alice.software_items.count", 1 do
      result = import(build_csv_with_software([], [
        { software_name: sw_name, barter_status: "no_barter" }
      ]))
      assert result[:success], result[:error]
      assert_equal 1, result[:software_item_count]
    end
  end

  test "imported software_item has correct attributes" do
    sw_name      = software_names(:tops20).name
    sw_condition = software_conditions(:complete).name
    import(build_csv_with_software([], [{
      software_name: sw_name, software_version: "V7.0",
      software_condition: sw_condition, software_description: "TOPS-20 OS",
      software_history: "Production system", barter_status: "offered"
    }]))
    item = @alice.software_items.find_by!(description: "TOPS-20 OS")
    assert_equal sw_name,      item.software_name.name
    assert_equal sw_condition, item.software_condition.name
    assert_equal "V7.0",       item.version
    assert item.barter_status_offered?
  end

  test "software_item with unknown computer model+serial imports as unattached with warning" do
    sw_name = software_names(:tops20).name
    result = import(build_csv_with_software([], [{
      software_name: sw_name, installed_on_model: "PDP-11/70",
      computer_serial_number: "DOES-NOT-EXIST-SN", barter_status: "no_barter"
    }]))
    assert result[:success], result[:error]
    assert result[:row_warnings].any?, "Expected a row_warning for unresolved computer"
    item = @alice.software_items.find_by!(software_name: software_names(:tops20))
    assert_nil item.computer
  end

  test "duplicate software_item is silently skipped" do
    item = software_items(:alice_vms)
    assert_no_difference "@alice.software_items.count" do
      result = import(build_csv_with_software([], [{
        software_name:          item.software_name.name,
        computer_serial_number: item.computer.serial_number,
        software_version:       item.version,
        barter_status:          "no_barter"
      }]))
      assert result[:success], result[:error]
      assert_equal 0, result[:software_item_count]
    end
  end

  test "unknown software_name is a row error (partial success)" do
    result = import(build_csv_with_software([], [
      { software_name: "Nonexistent OS 9000", barter_status: "no_barter" }
    ]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "Nonexistent OS 9000", result[:row_errors].first
  end

  # ── Required field validation (now row_errors, not file failure) ──────────

  test "computer row without serial_number produces a row_error" do
    result = import(build_csv(computer_rows: [
      comp("computer", "PDP-11/70", nil, nil)
    ]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "serial_number", result[:row_errors].first
  end

  test "computer row without model produces a row_error" do
    result = import(build_csv(computer_rows: [
      comp("computer", nil, nil, "NO-MODEL-SN")
    ]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "model", result[:row_errors].first
  end

  test "component row without type produces a row_error" do
    result = import(build_csv(component_rows: [
      cmp(nil, nil, nil, "integral", nil, "NO-TYPE-SN", nil, "No type", "no_barter")
    ]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "type", result[:row_errors].first
  end

  test "unknown computer model produces a row_error" do
    result = import(build_csv(computer_rows: [
      comp("computer", "Does Not Exist 9000", nil, "LOOKUP-SN-01")
    ]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "Does Not Exist 9000", result[:row_errors].first
  end

  test "unknown computer condition produces a row_error" do
    result = import(build_csv(computer_rows: [
      comp("computer", "PDP-11/70", nil, "COND-ERR-SN", "Nonexistent Condition")
    ]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "Nonexistent Condition", result[:row_errors].first
  end

  test "unknown run_status produces a row_error" do
    result = import(build_csv(computer_rows: [
      comp("computer", "PDP-11/70", nil, "RS-ERR-SN", nil, "Phantom Status")
    ]))
    assert result[:success]
    assert result[:row_errors].any?
    assert_match "Phantom Status", result[:row_errors].first
  end

  # ── File-level validation (still returns success: false) ──────────────────

  test "nil file fails gracefully" do
    result = OwnerImportService.process(@alice, nil)
    refute result[:success]
    assert_match "No file provided", result[:error]
  end

  test "non-CSV file is rejected" do
    result = OwnerImportService.process(@alice,
      csv_upload("some content", filename: "data.txt", content_type: "text/plain"))
    refute result[:success]
    assert_match "CSV", result[:error]
  end

  # ── Legacy format backward compatibility ──────────────────────────────────

  test "legacy format CSV (global header row) is still accepted" do
    # Legacy format: first non-comment row is the global 12-column header.
    legacy_headers = %w[record_type computer_model computer_order_number
                        computer_serial_number computer_condition computer_run_status
                        computer_history component_type component_order_number
                        component_serial_number component_condition component_description]
    csv = CSV.generate(headers: true, force_quotes: true) do |c|
      c << legacy_headers
      c << ["computer", "PDP-11/70", nil, "LEGACY-SN-001",
            nil, nil, nil, nil, nil, nil, nil, nil]
    end
    assert_difference "@alice.computers.count", 1 do
      result = import(csv)
      assert result[:success], result[:error]
      assert_equal 1, result[:computer_count]
    end
  end

  private

  # ── CSV builder helpers ───────────────────────────────────────────────────

  # Builds a new-format CSV with optional computers, peripherals, components sections.
  # comment_rows: array of strings (each becomes a row with the string as first cell).
  # computer_rows / peripheral_rows: arrays of row arrays matching COMPUTER_SECTION_HEADERS.
  # component_rows: arrays of row arrays matching COMPONENT_SECTION_HEADERS.
  def build_csv(computer_rows: [], peripheral_rows: [], component_rows: [], comment_rows: [])
    CSV.generate(force_quotes: true) do |csv|
      csv << ["# test import"]
      comment_rows.each { |c| csv << [c] }
      unless computer_rows.empty?
        csv << ["! --- computers ---"]
        csv << OwnerExportService::COMPUTER_SECTION_HEADERS
        computer_rows.each { |r| csv << r }
      end
      unless peripheral_rows.empty?
        csv << ["! --- peripherals ---"]
        csv << OwnerExportService::COMPUTER_SECTION_HEADERS
        peripheral_rows.each { |r| csv << r }
      end
      unless component_rows.empty?
        csv << ["! --- components ---"]
        csv << OwnerExportService::COMPONENT_SECTION_HEADERS
        component_rows.each { |r| csv << r }
      end
    end
  end

  # Builds a new-format CSV with device rows and a connections section.
  # connection_groups_data: array of hashes with :owner_group_id, :type, :label, :members.
  def build_csv_with_connections(computer_rows, connection_groups_data)
    CSV.generate(force_quotes: true) do |csv|
      csv << ["# test import"]
      unless computer_rows.empty?
        csv << ["! --- computers ---"]
        csv << OwnerExportService::COMPUTER_SECTION_HEADERS
        computer_rows.each { |r| csv << r }
      end
      csv << ["! --- connections ---"]
      csv << OwnerExportService::CONNECTION_SECTION_HEADERS
      connection_groups_data.each do |g|
        csv << ["connection_group", g[:owner_group_id], g[:type], g[:label], nil]
        g[:members].each do |m|
          csv << ["connection_member", nil, m[:model], nil, m[:serial]]
        end
      end
    end
  end

  # Builds a new-format CSV with device rows and a software section.
  # software_items_data: array of hashes. Keys: :software_name (req), :software_version,
  #   :software_condition, :software_description, :software_history, :barter_status,
  #   :computer_serial_number, :installed_on_model.
  def build_csv_with_software(computer_rows, software_items_data)
    CSV.generate(force_quotes: true) do |csv|
      csv << ["# test import"]
      unless computer_rows.empty?
        csv << ["! --- computers ---"]
        csv << OwnerExportService::COMPUTER_SECTION_HEADERS
        computer_rows.each { |r| csv << r }
      end
      csv << ["! --- software ---"]
      csv << OwnerExportService::SOFTWARE_SECTION_HEADERS
      software_items_data.each do |s|
        csv << [
          "software_item",
          s[:installed_on_model],
          s[:computer_serial_number],
          s[:software_name],
          s[:software_version],
          s[:software_condition],
          s[:software_description],
          s[:software_history],
          s[:barter_status]
        ]
      end
    end
  end

  # Short helper for a computer/peripheral row (COMPUTER_SECTION_HEADERS order).
  def comp(record_type, model, order_number = nil, serial_number = nil,
           condition = nil, run_status = nil, history = nil, barter_status = nil)
    [record_type, model, order_number, serial_number,
     condition, run_status, history, barter_status]
  end

  # Short helper for a component row (COMPONENT_SECTION_HEADERS order):
  #   record_type, installed_on_model, installed_on_serial, type, category,
  #   order_number, serial_number, condition, description, barter_status
  def cmp(installed_on_model, installed_on_serial, type_name, category = "integral",
          order_number = nil, serial_number = nil, condition = nil,
          description = nil, barter_status = nil)
    ["component", installed_on_model, installed_on_serial, type_name, category,
     order_number, serial_number, condition, description, barter_status]
  end

  def import(csv_content)
    OwnerImportService.process(@alice, csv_upload(csv_content))
  end

  def csv_upload(content, filename: "test_import.csv", content_type: "text/csv")
    tmp = Tempfile.new(["import_test", ".csv"])
    tmp.write(content)
    tmp.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: tmp, filename: filename, type: content_type,
      head: "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\""
    )
  end
end
