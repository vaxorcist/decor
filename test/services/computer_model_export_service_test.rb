# decor/test/services/computer_model_export_service_test.rb
# version 1.2
# v1.2 (Session 41): Appliances → Peripherals merger Phase 4.
#   Removed entire "Appliance export" section — hsc50 is now device_type: 2
#   (peripheral) after the merger; querying device_type: :appliance (1) returns
#   zero rows.
#   Fixed peripheral export tests: hsc50 (formerly appliance fixture) is now
#   a peripheral fixture, so it now appears in the peripheral export. Removed
#   the assertion that hsc50 must NOT appear in peripheral export.
#   Updated fixture baseline comment accordingly.
# v1.1 (Session 29): Added peripheral export tests section.
# v1.0 (Session 24): New test file — ComputerModelExportService.
#
# Fixture baseline (computer_models.yml v1.3):
#   pdp11_70  name: PDP-11/70   device_type: 0 (computer)
#   pdp8      name: PDP-8       device_type: 0 (computer)
#   vax11_780 name: VAX-11/780  device_type: 0 (computer)
#   pdp10     name: PDP-10      device_type: 0 (computer)
#   vt100     name: VT100       device_type: 0 (computer)
#   hsc50     name: HSC50       device_type: 2 (peripheral — formerly appliance)
#   dec_vt278 name: DEC VT278   device_type: 2 (peripheral)
#
# Computer export: 5 rows (device_type: 0)
# Peripheral export: at least 2 rows (hsc50 + dec_vt278 from fixtures)

require "test_helper"
require "csv"

class ComputerModelExportServiceTest < ActiveSupport::TestCase
  # ── Computer export ────────────────────────────────────────────────────────

  setup do
    @computer_csv_string = ComputerModelExportService.export(device_type: :computer)
    @computer_csv        = CSV.parse(@computer_csv_string, headers: true)
  end

  test "computer export has correct headers" do
    assert_equal ComputerModelExportService::CSV_HEADERS, @computer_csv.headers
  end

  test "computer export contains correct number of rows" do
    # Fixtures have 5 computer models (device_type: 0)
    assert_equal 5, @computer_csv.size
  end

  test "computer export includes expected model names" do
    names = @computer_csv.map { |row| row["name"] }
    assert_includes names, "PDP-11/70"
    assert_includes names, "PDP-8"
    assert_includes names, "VAX-11/780"
    assert_includes names, "PDP-10"
    assert_includes names, "VT100"
  end

  test "computer export does NOT include peripheral models" do
    names = @computer_csv.map { |row| row["name"] }
    refute_includes names, "HSC50",     "Peripheral model must not appear in computer export"
    refute_includes names, "DEC VT278", "Peripheral model must not appear in computer export"
  end

  test "computer export rows are sorted alphabetically by name" do
    names = @computer_csv.map { |row| row["name"] }
    assert_equal names.sort, names
  end

  # ── Peripheral export ──────────────────────────────────────────────────────
  #
  # hsc50 is now device_type: 2 (peripheral) after the Session 41 appliance merger.
  # Both hsc50 and dec_vt278 are peripheral fixtures and appear in the peripheral export.

  test "peripheral export has correct headers" do
    csv = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    assert_equal ComputerModelExportService::CSV_HEADERS, csv.headers
  end

  test "peripheral export includes hsc50 (formerly appliance, now peripheral)" do
    # hsc50 was device_type: 1 (appliance) before Session 41; it is now device_type: 2.
    csv   = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    names = csv.map { |row| row["name"] }
    assert_includes names, "HSC50",
                    "HSC50 is now a peripheral fixture and must appear in peripheral export"
  end

  test "peripheral export includes dynamically-created peripheral model" do
    ComputerModel.create!(name: "LA120", device_type: :peripheral)

    csv   = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    names = csv.map { |row| row["name"] }

    assert_includes names, "LA120", "Dynamically-created peripheral must appear in peripheral export"
  end

  test "peripheral export does NOT include computer models" do
    csv   = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    names = csv.map { |row| row["name"] }

    refute_includes names, "PDP-11/70", "Computer model must not appear in peripheral export"
    refute_includes names, "PDP-8",     "Computer model must not appear in peripheral export"
  end

  test "peripheral export row count matches live DB peripheral count" do
    expected = ComputerModel.where(device_type: :peripheral).count
    csv = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    assert_equal expected, csv.size
  end

  test "peripheral export rows are sorted alphabetically by name" do
    ComputerModel.create!(name: "VT220", device_type: :peripheral)
    ComputerModel.create!(name: "LA120", device_type: :peripheral)

    csv   = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    names = csv.map { |row| row["name"] }

    assert_equal names.sort, names, "Peripheral export must be sorted alphabetically by name"
  end

  # ── Empty state ────────────────────────────────────────────────────────────

  test "export row count matches live DB count for the requested device_type" do
    expected_count = ComputerModel.where(device_type: :computer).count
    assert_equal expected_count, @computer_csv.size
  end
end
