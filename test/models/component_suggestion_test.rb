# decor/test/models/component_suggestion_test.rb
# version 1.0
# Session 63: Phase 1 of Component Suggestions feature.
#
# Tests for ComponentSuggestion model validations and the :matching scope.
#
# Fixtures used (component_suggestions.yml v1.0):
#   delqa       — order_number: "DELQA",    description: present, category: present
#   m7516       — order_number: "M7516",    description: present, category: present
#   pcb_assembly— order_number: "54-17647", description: present, category: present
#   rev_a3_rom  — order_number: "23-304E5", description: present, category: present

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

  test "is valid without description" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-001", description: nil)
    assert suggestion.valid?, suggestion.errors.full_messages.inspect
  end

  test "is invalid with description longer than 100 characters" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-002", description: "X" * 101)
    assert_not suggestion.valid?
    assert suggestion.errors[:description].any?
  end

  test "is valid with description of exactly 100 characters" do
    suggestion = ComponentSuggestion.new(order_number: "UNIQ-003", description: "X" * 100)
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
end
