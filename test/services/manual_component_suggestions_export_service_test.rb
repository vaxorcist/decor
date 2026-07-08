# decor/test/services/manual_component_suggestions_export_service_test.rb
# version 1.0
# Session 67: Phase 4 item 2 — "Download Manual Changes" admin feature.
#
# Tests for ManualComponentSuggestionsExportService.
# Pattern: mirrors component_suggestion_export_service_test.rb (Session 63).
#
# Fixture baseline (component_suggestions.yml v1.0): all four fixtures have
# manual: nil (see component_suggestion_test.rb "fixtures are all untouched
# bulk-import rows" test) — so none of them should appear in this export.
# Every row exercised here is created fresh in-test with an explicit manual
# value, per PROGRAMMING_GENERAL.md "Derive Test Assertions from Data, Not
# Constants" — no hardcoded row-count assumption about the fixture set.

require "test_helper"
require "csv"

class ManualComponentSuggestionsExportServiceTest < ActiveSupport::TestCase
  # ── Headers ───────────────────────────────────────────────────────────────

  test "export has correct headers" do
    csv = CSV.parse(ManualComponentSuggestionsExportService.export, headers: true)
    assert_equal ManualComponentSuggestionsExportService::CSV_HEADERS, csv.headers
  end

  # ── Filtering — only manual rows included ─────────────────────────────────

  test "export excludes untouched bulk-import rows (manual: nil)" do
    # The four Session 63 fixtures are all manual: nil — none should appear.
    csv = CSV.parse(ManualComponentSuggestionsExportService.export, headers: true)
    order_numbers = csv.map { |r| r["order_number"] }
    refute_includes order_numbers, component_suggestions(:delqa).order_number
    refute_includes order_numbers, component_suggestions(:m7516).order_number
  end

  test "export includes an 'added' row" do
    ComponentSuggestion.create!(order_number: "MANUAL-EXPORT-ADDED", manual: "added")

    csv = CSV.parse(ManualComponentSuggestionsExportService.export, headers: true)
    row = csv.find { |r| r["order_number"] == "MANUAL-EXPORT-ADDED" }

    assert_not_nil row, "an 'added' row must appear in the manual export"
    assert_equal "a", row["manual"], "manual column must contain the raw enum value, not the humanized label"
  end

  test "export includes a 'modified' row" do
    ComponentSuggestion.create!(order_number: "EXPORT-MODIFIED-01", manual: "modified")

    csv = CSV.parse(ManualComponentSuggestionsExportService.export, headers: true)
    row = csv.find { |r| r["order_number"] == "EXPORT-MODIFIED-01" }

    assert_not_nil row, "a 'modified' row must appear in the manual export"
    assert_equal "m", row["manual"]
  end

  test "export includes both added and modified rows together in one download" do
    # Confirmed Session 66 design decision: "both together, one download".
    ComponentSuggestion.create!(order_number: "MANUAL-BOTH-A", manual: "added")
    ComponentSuggestion.create!(order_number: "MANUAL-BOTH-M", manual: "modified")

    csv = CSV.parse(ManualComponentSuggestionsExportService.export, headers: true)
    order_numbers = csv.map { |r| r["order_number"] }

    assert_includes order_numbers, "MANUAL-BOTH-A"
    assert_includes order_numbers, "MANUAL-BOTH-M"
  end

  # ── Sort order ────────────────────────────────────────────────────────────

  test "export rows are sorted alphabetically by order_number" do
    ComponentSuggestion.create!(order_number: "ZZZ-MANUAL", manual: "added")
    ComponentSuggestion.create!(order_number: "AAA-MANUAL", manual: "modified")

    csv = CSV.parse(ManualComponentSuggestionsExportService.export, headers: true)
    order_numbers = csv.map { |r| r["order_number"] }

    assert_equal order_numbers.sort, order_numbers,
                 "Manual export must be sorted alphabetically by order_number"
  end

  # ── Content — other columns ────────────────────────────────────────────────

  test "export includes description and category alongside the manual flag" do
    ComponentSuggestion.create!(order_number: "MANUAL-FULL-ROW", description: "Full Row Desc",
                                 category: "Part", manual: "added")

    csv = CSV.parse(ManualComponentSuggestionsExportService.export, headers: true)
    row = csv.find { |r| r["order_number"] == "MANUAL-FULL-ROW" }

    assert_equal "Full Row Desc", row["description"]
    assert_equal "Part",          row["category"]
    assert_equal "a",             row["manual"]
  end
end
