# decor/test/models/component_suggestion_test.rb
# version 1.1
# Session 67: Phase 4 changes.
#   - description max length changed from 100 to 510 (migration
#     20260707000100) — updated the three length-boundary tests accordingly
#     (was "invalid at 101 / valid at exactly 100"; now "invalid at 511 /
#     valid at exactly 510").
#   - Added a new "manual enum" section: added?/modified? predicates, nil
#     default, and that assigning an unmapped string raises (Rails enum
#     behavior) — confirms component_suggestion.rb v1.1's
#     enum :manual, { added: "a", modified: "m" }, prefix: true.
# Session 63: Phase 1 of Component Suggestions feature.
#
# Tests for ComponentSuggestion model validations and the :matching scope.
#
# Fixtures used (component_suggestions.yml v1.0):
#   delqa       — order_number: "DELQA",    description: present, category: present
#   m7516       — order_number: "M7516",    description: present, category: present
#   pcb_assembly— order_number: "54-17647", description: present, category: present
#   rev_a3_rom  — order_number: "23-304E5", description: present, category: present
# None of the fixtures set "manual" — all four are untouched bulk-import rows
# (manual: nil), which is the correct baseline state per component_suggestion.rb v1.1.

require "test_helper"

class ComponentSuggestionTest < ActiveSupport::TestCase
  # ── Fixtures are valid ────────────────────────────────────────────────────

  test "fixture delqa is valid" do
    assert component_suggestions(:delqa).valid?
  end

  test "fixture m7516 is valid" do
    assert component_suggestions(:m7516).valid?
  end

  # ── order_number validations ──────────────────────────────────────────────

  test "is invalid without order_number" do
    suggestion = ComponentSuggestion.new(order_number: nil)
    assert_not suggestion.valid?
    assert_includes suggestion.errors[:order_number], "can't be blank"
  end

  test "is invalid with blank order_number" do
    suggestion = ComponentSuggestion.new(order_number: "   ")
    assert_not suggestion.valid?
    assert_includes suggestion.errors[:order_number], "can't be blank"
  end

  test "is invalid with order_number longer than 20 characters" do
    suggestion = ComponentSuggestion.new(order_number: "A" * 21)
    assert_not suggestion.valid?
    assert suggestion.errors[:order_number].any?
  end

  test "is valid with order_number of exactly 20 characters" do
    suggestion = ComponentSuggestion.new(order_number: "A" * 20)
    assert suggestion.valid?, suggestion.errors.full_messages.inspect
  end

  test "is invalid with duplicate order_number" do
    existing = component_suggestions(:delqa)
    suggestion = ComponentSuggestion.new(order_number: existing.order_number)
    assert_not suggestion.valid?
    assert suggestion.errors[:order_number].any?
  end

  # ── description validations ───────────────────────────────────────────────
  # Session 67: max length raised from 100 to 510 (migration 20260707000100) —
  # concatenated main + variant descriptions from the DEC-database export no
  # longer fit the original size.

  test "is valid without description" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-001", description: nil)
    assert suggestion.valid?, suggestion.errors.full_messages.inspect
  end

  test "is invalid with description longer than 510 characters" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-002", description: "X" * 511)
    assert_not suggestion.valid?
    assert suggestion.errors[:description].any?
  end

  test "is valid with description of exactly 510 characters" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-003", description: "X" * 510)
    assert suggestion.valid?, suggestion.errors.full_messages.inspect
  end

  # ── category validations ──────────────────────────────────────────────────

  test "is valid without category" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-004", category: nil)
    assert suggestion.valid?, suggestion.errors.full_messages.inspect
  end

  test "is invalid with category longer than 40 characters" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-005", category: "X" * 41)
    assert_not suggestion.valid?
    assert suggestion.errors[:category].any?
  end

  test "is valid with category of exactly 40 characters" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-006", category: "X" * 40)
    assert suggestion.valid?, suggestion.errors.full_messages.inspect
  end

  # ── manual enum (Session 67, Phase 4) ─────────────────────────────────────

  test "manual defaults to nil for an untouched bulk-import row" do
    suggestion = ComponentSuggestion.create!(order_number: "MANUAL-NIL-001")
    assert_nil suggestion.manual
    assert_not suggestion.manual_added?
    assert_not suggestion.manual_modified?
  end

  test "fixtures are all untouched bulk-import rows (manual: nil)" do
    # Confirms the baseline assumption documented in the file header above —
    # none of the four Session 63 fixtures were retrofitted with a manual value.
    assert_nil component_suggestions(:delqa).manual
    assert_nil component_suggestions(:m7516).manual
    assert_nil component_suggestions(:pcb_assembly).manual
    assert_nil component_suggestions(:rev_a3_rom).manual
  end

  test "manual can be set to added" do
    suggestion = ComponentSuggestion.create!(order_number: "MANUAL-ADDED-001", manual: "added")
    assert suggestion.manual_added?
    assert_equal "added", suggestion.manual
  end

  test "manual can be set to modified" do
    suggestion = ComponentSuggestion.create!(order_number: "MANUAL-MODIFIED-001", manual: "modified")
    assert suggestion.manual_modified?
    assert_equal "modified", suggestion.manual
  end

  test "manual raises ArgumentError for an unmapped value" do
    # Standard Rails enum behavior — confirms only "a"/"m" (added/modified)
    # are valid raw values; anything else is a programmer error, not
    # something that should silently succeed.
    suggestion = ComponentSuggestion.new(order_number: "MANUAL-BAD-001")
    assert_raises(ArgumentError) { suggestion.manual = "deleted" }
  end

  # ── :matching scope ───────────────────────────────────────────────────────

  test "matching scope returns records starting with query" do
    # Fixtures: DELQA, M7516, 54-17647, 23-304E5
    results = ComponentSuggestion.matching("DEL")
    assert_includes results.map(&:order_number), "DELQA"
    refute_includes results.map(&:order_number), "M7516"
  end

  test "matching scope returns all records matching a short prefix" do
    results = ComponentSuggestion.matching("M")
    assert_includes results.map(&:order_number), "M7516"
  end

  test "matching scope returns empty collection for no match" do
    results = ComponentSuggestion.matching("ZZZ")
    assert_empty results
  end

  test "matching scope returns results ordered by order_number" do
    # Create two more with the same prefix to verify sort
    ComponentSuggestion.create!(order_number: "DEL-BETA")
    ComponentSuggestion.create!(order_number: "DEL-ALPHA")

    names = ComponentSuggestion.matching("DEL").map(&:order_number)
    assert_equal names.sort, names, "matching scope must return results sorted by order_number"
  end

  test "matching scope returns all records for empty query string" do
    # LIKE "%" matches everything — useful to know for the JSON endpoint
    total = ComponentSuggestion.count
    results = ComponentSuggestion.matching("")
    assert_equal total, results.count
  end

  # ── :order_number_contains scope (Session 67, Phase 4 admin filter) ──────

  test "order_number_contains matches a substring anywhere in order_number" do
    # "17647" is in the middle of the pcb_assembly fixture's "54-17647" —
    # a prefix-only scope (:matching) would NOT find this.
    results = ComponentSuggestion.order_number_contains("17647")
    assert_includes results.map(&:order_number), "54-17647"
  end

  test "order_number_contains does not match :matching-only prefix behavior" do
    # Sanity check that the two scopes are genuinely different: "ELQA" is a
    # substring of DELQA but not a prefix.
    refute_includes ComponentSuggestion.matching("ELQA").map(&:order_number), "DELQA"
    assert_includes ComponentSuggestion.order_number_contains("ELQA").map(&:order_number), "DELQA"
  end

  test "order_number_contains returns empty collection for no match" do
    results = ComponentSuggestion.order_number_contains("NO-SUCH-SUBSTRING")
    assert_empty results
  end
end
