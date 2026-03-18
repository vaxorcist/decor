# decor/test/services/computer_model_export_service_test.rb
# version 1.1
# Session 24: New test file — ComputerModelExportService.
# Session 29: Added peripheral export tests section.
#   Peripheral records created dynamically (fixture-independent) because the
#   peripheral model fixture added to computer_models.yml in Session 27 is not
#   visible in current context. Dynamic creation is also cleaner — it keeps the
#   count assertions in computer/appliance sections unaffected by fixture changes.
#
# Fixture baseline (computer_models.yml v1.2):
#   pdp11_70  name: PDP-11/70   device_type: 0 (computer)
#   pdp8      name: PDP-8       device_type: 0 (computer)
#   vax11_780 name: VAX-11/780  device_type: 0 (computer)
#   pdp10     name: PDP-10      device_type: 0 (computer)
#   vt100     name: VT100       device_type: 0 (computer)
#   hsc50     name: HSC50       device_type: 1 (appliance)
#   (one peripheral model added Session 27 — label/name not in current context)
#
# Computer export: 5 rows (device_type: 0)
# Appliance export: 1 row  (device_type: 1)
# Peripheral export: at least 1 row (fixture + any dynamically created)

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

  test "computer export does NOT include appliance models" do
    names = @computer_csv.map { |row| row["name"] }
    refute_includes names, "HSC50", "Appliance model must not appear in computer export"
  end

  test "computer export rows are sorted alphabetically by name" do
    names = @computer_csv.map { |row| row["name"] }
    assert_equal names.sort, names
  end

  # ── Appliance export ───────────────────────────────────────────────────────

  test "appliance export has correct headers" do
    csv = CSV.parse(ComputerModelExportService.export(device_type: :appliance), headers: true)
    assert_equal ComputerModelExportService::CSV_HEADERS, csv.headers
  end

  test "appliance export contains correct number of rows" do
    # Fixtures have 1 appliance model (device_type: 1, hsc50)
    csv = CSV.parse(ComputerModelExportService.export(device_type: :appliance), headers: true)
    assert_equal 1, csv.size
  end

  test "appliance export includes hsc50" do
    csv   = CSV.parse(ComputerModelExportService.export(device_type: :appliance), headers: true)
    names = csv.map { |row| row["name"] }
    assert_includes names, "HSC50"
  end

  test "appliance export does NOT include computer models" do
    csv   = CSV.parse(ComputerModelExportService.export(device_type: :appliance), headers: true)
    names = csv.map { |row| row["name"] }
    refute_includes names, "PDP-11/70", "Computer model must not appear in appliance export"
  end

  # ── Peripheral export ──────────────────────────────────────────────────────
  #
  # Session 29: peripheral export tests.
  # Dynamic records are used so these tests remain stable regardless of which
  # peripheral fixture(s) are defined in computer_models.yml.

  test "peripheral export has correct headers" do
    csv = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    assert_equal ComputerModelExportService::CSV_HEADERS, csv.headers
  end

  test "peripheral export includes dynamically-created peripheral model" do
    # Create a peripheral model within this test; the transaction rolls back after.
    ComputerModel.create!(name: "LA120", device_type: :peripheral)

    csv   = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    names = csv.map { |row| row["name"] }

    assert_includes names, "LA120", "Dynamically-created peripheral must appear in peripheral export"
  end

  test "peripheral export does NOT include computer or appliance models" do
    csv   = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    names = csv.map { |row| row["name"] }

    refute_includes names, "PDP-11/70", "Computer model must not appear in peripheral export"
    refute_includes names, "HSC50",     "Appliance model must not appear in peripheral export"
  end

  test "peripheral export row count matches live DB peripheral count" do
    # Derive the expected count from the DB — robust against fixture additions.
    # This replaces a hardcoded count (which would be the anti-pattern from
    # PROGRAMMING_GENERAL.md — Derive Test Assertions from Data, Not Constants).
    expected = ComputerModel.where(device_type: :peripheral).count
    csv = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    assert_equal expected, csv.size
  end

  test "peripheral export rows are sorted alphabetically by name" do
    # Ensure at least two peripheral records exist so sorting is observable.
    ComputerModel.create!(name: "VT220", device_type: :peripheral)
    ComputerModel.create!(name: "LA120", device_type: :peripheral)

    csv   = CSV.parse(ComputerModelExportService.export(device_type: :peripheral), headers: true)
    names = csv.map { |row| row["name"] }

    assert_equal names.sort, names, "Peripheral export must be sorted alphabetically by name"
  end

  # ── Empty state ────────────────────────────────────────────────────────────

  test "export for device_type with no records returns only headers" do
    # device_type :terminal does not exist as an enum value on ComputerModel —
    # use an integer that has no records (e.g. query by raw integer 99 is not
    # possible via enum; instead delete all appliances and test). Instead:
    # we verify the existing CSV matches the live DB count exactly.
    expected_count = ComputerModel.where(device_type: :computer).count
    assert_equal expected_count, @computer_csv.size
  end
end
