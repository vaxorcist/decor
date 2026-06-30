# decor/test/services/component_suggestion_export_service_test.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Tests for ComponentSuggestionExportService.
# Pattern: mirrors computer_model_export_service_test.rb.
#
# Fixture baseline (component_suggestions.yml v1.0):
#   delqa       — order_number: "DELQA"
#   m7516       — order_number: "M7516"
#   pcb_assembly— order_number: "54-17647"
#   rev_a3_rom  — order_number: "23-304E5"
#   → 4 rows total

require "test_helper"
require "csv"

class ComponentSuggestionExportServiceTest < ActiveSupport::TestCase
  setup do
    @csv_string = ComponentSuggestionExportService.export
    @csv        = CSV.parse(@csv_string, headers: true)
  end

  # ── Headers ───────────────────────────────────────────────────────────────

  test "export has correct headers" do
    assert_equal ComponentSuggestionExportService::CSV_HEADERS, @csv.headers
  end

  # ── Row count ─────────────────────────────────────────────────────────────

  test "export row count matches live DB count" do
    assert_equal ComponentSuggestion.count, @csv.size
  end

  test "export contains all four fixture records" do
    assert_equal 4, @csv.size
  end

  # ── Content ───────────────────────────────────────────────────────────────

  test "export includes DELQA row with correct fields" do
    row = @csv.find { |r| r["order_number"] == "DELQA" }
    assert_not_nil row, "DELQA fixture must be present in export"
    assert_equal "DELQA Ethernet Controller", row["description"]
    assert_equal "Option",                    row["category"]
  end

  test "export includes M7516 row" do
    order_numbers = @csv.map { |r| r["order_number"] }
    assert_includes order_numbers, "M7516"
  end

  test "export includes hyphenated order numbers" do
    order_numbers = @csv.map { |r| r["order_number"] }
    assert_includes order_numbers, "54-17647"
    assert_includes order_numbers, "23-304E5"
  end

  # ── Sort order ────────────────────────────────────────────────────────────

  test "export rows are sorted alphabetically by order_number" do
    order_numbers = @csv.map { |r| r["order_number"] }
    assert_equal order_numbers.sort, order_numbers,
                 "Export must be sorted alphabetically by order_number"
  end

  # ── Blank optional fields ─────────────────────────────────────────────────

  test "export handles nil description as blank cell" do
    ComponentSuggestion.create!(order_number: "NO-DESC")
    csv = CSV.parse(ComponentSuggestionExportService.export, headers: true)
    row = csv.find { |r| r["order_number"] == "NO-DESC" }
    assert_not_nil row
    assert_nil row["description"].presence, "nil description must export as blank cell"
  end

  test "export handles nil category as blank cell" do
    ComponentSuggestion.create!(order_number: "NO-CAT")
    csv = CSV.parse(ComponentSuggestionExportService.export, headers: true)
    row = csv.find { |r| r["order_number"] == "NO-CAT" }
    assert_not_nil row
    assert_nil row["category"].presence, "nil category must export as blank cell"
  end

  # ── Dynamically created records ───────────────────────────────────────────

  test "export includes dynamically created record" do
    ComponentSuggestion.create!(order_number: "NEW-PART", description: "New Part", category: "Test")
    csv = CSV.parse(ComponentSuggestionExportService.export, headers: true)
    order_numbers = csv.map { |r| r["order_number"] }
    assert_includes order_numbers, "NEW-PART"
  end
end
