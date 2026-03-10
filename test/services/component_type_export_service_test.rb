# decor/test/services/component_type_export_service_test.rb
# version 1.0
# Session 24: New test file — ComponentTypeExportService.
#
# Fixture baseline (component_types.yml):
#   memory_board  name: Memory Board
#   cpu_board     name: CPU Board
#   disk_drive    name: Disk Drive
#   tape_drive    name: Tape Drive
#   power_supply  name: Power Supply
#   terminal      name: Terminal
#
# Total: 6 fixture records.

require "test_helper"
require "csv"

class ComponentTypeExportServiceTest < ActiveSupport::TestCase
  setup do
    @csv_string = ComponentTypeExportService.export
    @csv        = CSV.parse(@csv_string, headers: true)
  end

  test "export has correct headers" do
    assert_equal ComponentTypeExportService::CSV_HEADERS, @csv.headers
  end

  test "export contains correct number of rows" do
    # Derives count from live data rather than hardcoding 6, so adding a new
    # fixture later does not break this test.
    assert_equal ComponentType.count, @csv.size
  end

  test "export includes all fixture component type names" do
    names = @csv.map { |row| row["name"] }
    assert_includes names, "Memory Board"
    assert_includes names, "CPU Board"
    assert_includes names, "Disk Drive"
    assert_includes names, "Tape Drive"
    assert_includes names, "Power Supply"
    assert_includes names, "Terminal"
  end

  test "export rows are sorted alphabetically by name" do
    names = @csv.map { |row| row["name"] }
    assert_equal names.sort, names
  end

  test "each row has exactly the expected columns" do
    @csv.each_with_index do |row, i|
      assert_equal ComponentTypeExportService::CSV_HEADERS.length, row.length,
                   "Row #{i + 2} has wrong column count"
    end
  end
end
