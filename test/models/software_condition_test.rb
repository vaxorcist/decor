# decor/test/models/software_condition_test.rb
# version 1.0
# Session 43: Model tests for SoftwareCondition — admin-managed lookup table.
#   Parallel structure to SoftwareNameTest. Covers: fixture validity,
#   name presence/uniqueness/length, description optional length, and
#   restrict_with_error when items reference the condition.

require "test_helper"

class SoftwareConditionTest < ActiveSupport::TestCase
  def setup
    @complete = software_conditions(:complete)
  end

  # --- Fixture sanity ---

  test "complete fixture is valid" do
    assert @complete.valid?
  end

  # --- name: presence ---

  test "name must be present" do
    @complete.name = ""
    assert_not @complete.valid?
    assert @complete.errors[:name].any?
  end

  test "name cannot be nil" do
    @complete.name = nil
    assert_not @complete.valid?
    assert @complete.errors[:name].any?
  end

  # --- name: uniqueness ---

  test "name must be unique" do
    duplicate = SoftwareCondition.new(name: @complete.name)
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end

  test "different names are valid" do
    sc = SoftwareCondition.new(name: "Original Media")
    assert sc.valid?
  end

  # --- name: length ---

  test "name at exactly 40 characters is valid" do
    @complete.name = "A" * 40
    assert @complete.valid?
  end

  test "name at 41 characters is invalid" do
    @complete.name = "A" * 41
    assert_not @complete.valid?
    assert @complete.errors[:name].any?
  end

  # --- description: optional length ---

  test "description can be blank" do
    @complete.description = ""
    assert @complete.valid?
  end

  test "description can be nil" do
    @complete.description = nil
    assert @complete.valid?
  end

  test "description at exactly 100 characters is valid" do
    @complete.description = "A" * 100
    assert @complete.valid?
  end

  test "description at 101 characters is invalid" do
    @complete.description = "A" * 101
    assert_not @complete.valid?
    assert @complete.errors[:description].any?
  end

  # --- associations ---

  test "has many software items" do
    assert_respond_to @complete, :software_items
  end

  # restrict_with_error: cannot destroy a condition that is referenced by a software item.
  # alice_vms fixture references software_conditions(:complete).
  test "cannot be destroyed when software items reference it" do
    assert_not @complete.destroy
    assert @complete.errors[:base].any?
    assert SoftwareCondition.exists?(@complete.id), "complete condition should still exist after failed destroy"
  end

  # A condition with no referencing items can be destroyed.
  test "can be destroyed when no software items reference it" do
    condition = SoftwareCondition.create!(name: "Original Media")
    assert condition.destroy
    assert_not SoftwareCondition.exists?(condition.id)
  end
end
