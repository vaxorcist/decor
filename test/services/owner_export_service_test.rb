# decor/test/services/owner_export_service_test.rb
# version 2.1
# v2.1 (Storage Locations Session F): Added coverage for the new
#   "! --- storage_locations ---" section and the new "storage_location"
#   column on computer/component/software_item rows.
#   Deliberately does NOT modify test/fixtures/storage_locations.yml,
#   computers.yml, components.yml, or software_items.yml — alice (owners:one)
#   already owns the alice_attic storage_locations.yml fixture with no setup
#   needed, which covers "section present" and "row has correct name" for
#   free. Tests that need a computer/component/software_item ACTUALLY
#   assigned to a location do so via an in-test update! on an existing
#   fixture record, then re-export locally (the module-level @csv_string
#   set up in `setup` predates any such assignment, so those tests build
#   their own local export rather than relying on it) — same pattern
#   Session 91 established for storage_locations_controller_test.rb, kept
#   here for consistency and to avoid touching shared fixture state that
#   other test files may depend on (per RAILS_TESTING.md fixture-ownership
#   guidance and PROGRAMMING_GENERAL.md "Derive Test Assertions from Data").
#
# v2.0 (Session 49 — Session G): Complete rewrite for per-section CSV format (v1.7+).
#   Dropped all OwnerExportService::CSV_HEADERS and flat CSV.parse(headers: true) usage —
#   there is no longer a global header row; each section has its own column-declaration row.
#   New sections_from helper parses the CSV into a hash keyed by sentinel string.
#   Column name assertions updated: serial_number (was computer_serial_number),
#   model (was computer_model), condition/run_status/history (were computer_* prefixed),
#   installed_on_model/installed_on_serial for components, type (was component_type).
#   Added tests: barter_status on computers/components, installed_on_model on components,
#   owner_group_id on connection_group rows, section headers match service constants.
#
# v1.5 (Session 48): Software feature Session F.
# v1.4 (Session 41): Appliances → Peripherals merger.
#
# Fixture baseline (alice = owners(:one)):
#   Computers:  alice_pdp11 (SN12345, PDP-11/70), alice_vax (VAX-780-001, VAX-11/780),
#               unassigned_condition_test (TEST-001, PDP-11/70)
#   Components: pdp11_memory + pdp11_cpu (attached to alice_pdp11), spare_disk (spare)
#   Connections: alice_pdp11_vax (no type, label "Lab setup"; members: SN12345 + VAX-780-001)
#   Software:   alice_vms (on alice_pdp11), alice_rt11_spare (unattached)
#   Storage Locations: alice_attic (owner: one, name "Attic Shelf 3") — Session F baseline.
#     None of alice's computers/components/software_items are pre-assigned to a
#     storage location in the fixtures; tests needing an assignment set it via
#     update! inside the test itself (see v2.1 note above).

require "test_helper"
require "csv"

class OwnerExportServiceTest < ActiveSupport::TestCase
  setup do
    @alice      = owners(:one)
    @csv_string = OwnerExportService.export(@alice)
    @sections   = sections_from(@csv_string)
  end

  # ── Comment header ────────────────────────────────────────────────────────

  test "first row is a comment starting with '#'" do
    first = CSV.parse(@csv_string, headers: false).first.first
    assert first&.start_with?("#"), "First row must start with '#'"
  end

  test "comment row contains owner user_name and today's date" do
    first = CSV.parse(@csv_string, headers: false).first.first
    assert_match @alice.user_name, first
    assert_match Date.today.to_s,  first
  end

  # ── Section structure ─────────────────────────────────────────────────────

  test "computers section present when owner has computers" do
    assert @sections.key?("! --- computers ---")
  end

  test "computers section headers match COMPUTER_SECTION_HEADERS constant" do
    assert_equal OwnerExportService::COMPUTER_SECTION_HEADERS,
                 @sections["! --- computers ---"][:headers]
  end

  test "components section headers match COMPONENT_SECTION_HEADERS constant" do
    assert_equal OwnerExportService::COMPONENT_SECTION_HEADERS,
                 @sections["! --- components ---"][:headers]
  end

  test "connections section headers match CONNECTION_SECTION_HEADERS constant" do
    assert_equal OwnerExportService::CONNECTION_SECTION_HEADERS,
                 @sections["! --- connections ---"][:headers]
  end

  test "software section headers match SOFTWARE_SECTION_HEADERS constant" do
    assert_equal OwnerExportService::SOFTWARE_SECTION_HEADERS,
                 @sections["! --- software ---"][:headers]
  end

  test "no peripherals section when owner has no peripherals" do
    refute @sections.key?("! --- peripherals ---")
  end

  # ── Storage Locations section (Storage Locations Session F) ──────────────

  test "storage_locations section present when owner has storage locations" do
    # alice_attic (owners:one) is a Session A fixture — no setup needed.
    assert @sections.key?("! --- storage_locations ---")
  end

  test "storage_locations section headers match STORAGE_LOCATION_SECTION_HEADERS constant" do
    assert_equal OwnerExportService::STORAGE_LOCATION_SECTION_HEADERS,
                 @sections["! --- storage_locations ---"][:headers]
  end

  test "storage_location row has correct record_type" do
    row = section_rows("! --- storage_locations ---").find { |r| r["name"] == "Attic Shelf 3" }
    assert row, "Expected a storage_location row named 'Attic Shelf 3'"
    assert_equal "storage_location", row["record_type"]
  end

  test "storage_location row has correct name" do
    location = storage_locations(:alice_attic)
    row = section_rows("! --- storage_locations ---").find { |r| r["name"] == location.name }
    assert row, "Expected a storage_location row matching the alice_attic fixture's name"
  end

  test "no storage_locations section when owner has no storage locations" do
    empty = Owner.create!(user_name: "nostorloc1", email: "nsl1@e.com", password: "ValidTest2026!")
    refute sections_from(OwnerExportService.export(empty)).key?("! --- storage_locations ---")
  end

  test "storage_locations section appears before computers section" do
    keys       = @sections.keys
    stor_idx   = keys.index("! --- storage_locations ---")
    comp_idx   = keys.index("! --- computers ---")
    assert stor_idx < comp_idx, "storage_locations must precede computers" if stor_idx && comp_idx
  end

  test "computer row has blank storage_location when unassigned" do
    # alice_pdp11 carries no storage_location_id in the fixture (v2.1 baseline note above).
    assert_nil find_computer("SN12345")["storage_location"].presence
  end

  test "computer row has correct storage_location name when assigned" do
    computer = computers(:alice_pdp11)
    location = storage_locations(:alice_attic)
    computer.update!(storage_location: location)

    secs = sections_from(OwnerExportService.export(@alice))
    row  = secs["! --- computers ---"][:rows].find { |r| r["serial_number"] == "SN12345" }
    assert_equal location.name, row["storage_location"]
  end

  test "component row has blank storage_location when unassigned" do
    # pdp11_memory carries no storage_location_id in the fixture (v2.1 baseline note above).
    assert_nil find_component("Memory Board")["storage_location"].presence
  end

  test "component row has correct storage_location name when assigned" do
    component = components(:pdp11_memory)
    location  = storage_locations(:alice_attic)
    component.update!(storage_location: location)

    secs = sections_from(OwnerExportService.export(@alice))
    row  = secs["! --- components ---"][:rows].find { |r| r["type"] == "Memory Board" }
    assert_equal location.name, row["storage_location"]
  end

  test "software_item row has correct storage_location name when assigned" do
    item     = software_items(:alice_vms)
    location = storage_locations(:alice_attic)
    item.update!(storage_location: location)

    secs = sections_from(OwnerExportService.export(@alice))
    row  = secs["! --- software ---"][:rows].find { |r| r["name"] == item.software_name.name }
    assert_equal location.name, row["storage_location"]
  end

  # ── Row counts ────────────────────────────────────────────────────────────

  test "device row count equals owner computer count" do
    count = (section_rows("! --- computers ---") + section_rows("! --- peripherals ---")).size
    assert_equal @alice.computers.count, count
  end

  test "component row count equals owner component count" do
    assert_equal @alice.components.count, section_rows("! --- components ---").size
  end

  test "software_item row count equals owner software_items count" do
    assert_equal @alice.software_items.count, section_rows("! --- software ---").size
  end

  test "storage_location row count equals owner storage_locations count" do
    assert_equal @alice.storage_locations.count, section_rows("! --- storage_locations ---").size
  end

  # ── Computers section content ─────────────────────────────────────────────

  test "computer row has correct record_type" do
    assert_equal "computer", find_computer("SN12345")["record_type"]
  end

  test "computer row has correct model name" do
    assert_equal "PDP-11/70", find_computer("SN12345")["model"]
  end

  test "computer row has correct serial_number" do
    assert_equal "SN12345", find_computer("SN12345")["serial_number"]
  end

  test "computer row has correct order_number" do
    assert_equal "ORD-1985-001", find_computer("SN12345")["order_number"]
  end

  test "computer row has correct condition" do
    assert_equal "Completely original", find_computer("SN12345")["condition"]
  end

  test "computer row has correct run_status" do
    assert_equal "Working", find_computer("SN12345")["run_status"]
  end

  test "computer row has correct history" do
    assert_equal "Originally used at MIT for student labs.",
                 find_computer("SN12345")["history"]
  end

  test "computer row carries barter_status string key (derived from fixture)" do
    computer = computers(:alice_pdp11)
    assert_equal computer.barter_status, find_computer("SN12345")["barter_status"]
  end

  test "computer with blank history exports blank history" do
    assert_nil find_computer("VAX-780-001")["history"].presence
  end

  test "within computers section rows are sorted by model then serial" do
    models = section_rows("! --- computers ---").map { |r| r["model"] }
    last_pdp  = models.rindex("PDP-11/70")
    first_vax = models.index("VAX-11/780")
    assert last_pdp < first_vax, "PDP-11/70 rows must precede VAX-11/780" if last_pdp && first_vax
  end

  # ── Peripheral section ────────────────────────────────────────────────────

  test "peripheral exports with record_type 'peripheral'" do
    charlie = owners(:three)
    secs    = sections_from(OwnerExportService.export(charlie))
    rows    = secs["! --- peripherals ---"]&.dig(:rows) || []
    assert rows.any? { |r| r["serial_number"] == "RTR-001" }
  end

  test "peripheral does NOT appear in computers section" do
    charlie   = owners(:three)
    secs      = sections_from(OwnerExportService.export(charlie))
    comp_rows = secs["! --- computers ---"]&.dig(:rows) || []
    refute comp_rows.any? { |r| r["serial_number"] == "RTR-001" }
  end

  # ── Components section content ────────────────────────────────────────────

  test "attached component carries installed_on_serial" do
    assert_equal "SN12345", find_component("Memory Board")["installed_on_serial"]
  end

  test "attached component carries installed_on_model" do
    # v1.9 fix: model is required to unambiguously identify parent on re-import.
    assert_equal "PDP-11/70", find_component("Memory Board")["installed_on_model"]
  end

  test "spare component has blank installed_on_serial" do
    assert_nil find_component("Disk Drive")["installed_on_serial"].presence
  end

  test "spare component has blank installed_on_model" do
    assert_nil find_component("Disk Drive")["installed_on_model"].presence
  end

  test "component row has correct type name" do
    assert_equal "CPU Board", find_component("CPU Board")["type"]
  end

  test "component row has correct description" do
    assert_equal "Original 256KB core memory board",
                 find_component("Memory Board")["description"]
  end

  test "component row carries barter_status string key" do
    component = @alice.components.joins(:component_type)
                      .find_by(component_types: { name: "Memory Board" })
    assert_equal component.barter_status, find_component("Memory Board")["barter_status"]
  end

  # ── Connections section content ───────────────────────────────────────────

  test "connection_group row carries owner_group_id" do
    group     = @alice.connection_groups.first
    group_row = section_rows("! --- connections ---")
                  .find { |r| r["record_type"] == "connection_group" }
    assert_not_nil group_row
    assert_equal group.owner_group_id.to_s, group_row["owner_group_id"]
  end

  test "connection_group row with no type has blank connection_type_or_model" do
    group_row = section_rows("! --- connections ---")
                  .find { |r| r["record_type"] == "connection_group" }
    assert_nil group_row["connection_type_or_model"].presence
  end

  test "connection_group row carries group label" do
    group_row = section_rows("! --- connections ---")
                  .find { |r| r["record_type"] == "connection_group" }
    assert_equal "Lab setup", group_row["label"]
  end

  test "connection_member rows carry model and serial" do
    member_rows = section_rows("! --- connections ---")
                    .select { |r| r["record_type"] == "connection_member" }
    assert_includes member_rows.map { |r| r["serial_number"] }, "SN12345"
    assert_includes member_rows.map { |r| r["serial_number"] }, "VAX-780-001"
    assert_includes member_rows.map { |r| r["connection_type_or_model"] }, "PDP-11/70"
  end

  test "connection_member rows have blank owner_group_id" do
    member_rows = section_rows("! --- connections ---")
                    .select { |r| r["record_type"] == "connection_member" }
    assert member_rows.any?
    assert member_rows.all? { |r| r["owner_group_id"].blank? }
  end

  test "no connections section when owner has no connection groups" do
    empty = Owner.create!(user_name: "noconn_ex01", email: "nc1@e.com", password: "ValidTest2026!")
    refute sections_from(OwnerExportService.export(empty)).key?("! --- connections ---")
  end

  test "connection group with connection_type exports type name in connection_type_or_model" do
    owner = Owner.create!(user_name: "cgtypetest3", email: "cgt3@e.com", password: "ValidTest2026!")
    c1 = owner.computers.create!(serial_number: "CGT3-001",
                                  computer_model: computer_models(:pdp11_70), device_type: :computer)
    c2 = owner.computers.create!(serial_number: "CGT3-002",
                                  computer_model: computer_models(:vax11_780), device_type: :computer)
    g = owner.connection_groups.build(connection_type: connection_types(:rs232), label: "test")
    g.connection_members.build(computer: c1)
    g.connection_members.build(computer: c2)
    g.save!

    secs = sections_from(OwnerExportService.export(owner))
    row  = secs["! --- connections ---"][:rows].find { |r| r["record_type"] == "connection_group" }
    assert_equal "RS-232 Serial", row["connection_type_or_model"]
  end

  # ── Software section content ──────────────────────────────────────────────

  test "software sentinel present when owner has software items" do
    assert @sections.key?("! --- software ---")
  end

  test "no software section when owner has no software items" do
    empty = Owner.create!(user_name: "noswtest02", email: "nsw2@e.com", password: "ValidTest2026!")
    refute sections_from(OwnerExportService.export(empty)).key?("! --- software ---")
  end

  test "software_item row carries installed_on_serial" do
    item = software_items(:alice_vms)
    assert_equal item.computer.serial_number,
                 find_software(item.software_name.name)["installed_on_serial"]
  end

  test "software_item row carries installed_on_model" do
    item = software_items(:alice_vms)
    assert_equal item.computer.computer_model.name,
                 find_software(item.software_name.name)["installed_on_model"]
  end

  test "software_item row carries correct version" do
    item = software_items(:alice_vms)
    assert_equal item.version, find_software(item.software_name.name)["version"]
  end

  test "software_item row carries correct condition name" do
    item = software_items(:alice_vms)
    assert_equal item.software_condition.name,
                 find_software(item.software_name.name)["condition"]
  end

  test "software_item row carries correct barter_status string key" do
    item = software_items(:alice_vms)
    assert_equal item.barter_status, find_software(item.software_name.name)["barter_status"]
  end

  test "unattached software_item has blank installed_on_serial and installed_on_model" do
    item = software_items(:alice_rt11_spare)
    row  = find_software(item.software_name.name)
    assert_nil row["installed_on_serial"].presence
    assert_nil row["installed_on_model"].presence
  end

  test "software section appears after connections section" do
    keys      = @sections.keys
    conn_idx  = keys.index("! --- connections ---")
    sw_idx    = keys.index("! --- software ---")
    assert conn_idx < sw_idx, "Connections must precede software" if conn_idx && sw_idx
  end

  # ── Owner isolation ───────────────────────────────────────────────────────

  test "export contains only the given owner's computers" do
    serials = section_rows("! --- computers ---").map { |r| r["serial_number"] }
    refute_includes serials, "PDP8-7891"
    refute_includes serials, "VT100-5432"
  end

  test "export for owner with no records returns only a comment row" do
    empty = Owner.create!(user_name: "emptyown04", email: "e4@e.com", password: "ValidTest2026!")
    rows  = CSV.parse(OwnerExportService.export(empty), headers: false)
    assert_equal 1, rows.size
    assert rows.first.first.start_with?("#")
  end

  private

  # Parses per-section CSV into { "! --- sentinel ---" => { headers: [...], rows: [...] } }.
  def sections_from(csv_string)
    result  = {}
    current = nil
    CSV.parse(csv_string, headers: false).each do |raw_row|
      first = raw_row.first&.strip
      next if first.blank? || first.start_with?("#")
      if first.start_with?("!")
        current = first
        result[current] = { headers: nil, rows: [] }
      elsif current && result[current][:headers].nil?
        result[current][:headers] = raw_row.map { |c| c&.strip }
      elsif current
        result[current][:rows] <<
          CSV::Row.new(result[current][:headers], raw_row.map(&:itself))
      end
    end
    result
  end

  def section_rows(sentinel)
    @sections[sentinel]&.dig(:rows) || []
  end

  def find_computer(serial)
    row = section_rows("! --- computers ---").find { |r| r["serial_number"] == serial }
    assert row, "Expected computer row with serial '#{serial}'"
    row
  end

  def find_component(type_name)
    row = section_rows("! --- components ---").find { |r| r["type"] == type_name }
    assert row, "Expected component row with type '#{type_name}'"
    row
  end

  def find_software(name)
    section_rows("! --- software ---").find { |r| r["name"] == name }
  end
end
