# decor/test/models/computer_condition_test.rb
# version 1.0
# Renamed from condition_test.rb following the conditions → computer_conditions
# table rename and Condition → ComputerCondition class rename (Session 7).
# Replaces: decor/test/models/condition_test.rb (delete that file)
# All Condition references updated to ComputerCondition.
# All conditions(:label) fixture helpers updated to computer_conditions(:label).

require "test_helper"

class ComputerConditionTest < ActiveSupport::TestCase
  test "valid with name" do
    condition = ComputerCondition.new(name: "Test Condition")
    assert condition.valid?
  end

  test "invalid without name" do
    condition = ComputerCondition.new(name: nil)
    assert_not condition.valid?
    assert_includes condition.errors[:name], "can't be blank"
  end

  test "invalid with duplicate name" do
    ComputerCondition.create!(name: "Unique Condition")
    condition = ComputerCondition.new(name: "Unique Condition")
    assert_not condition.valid?
    assert_includes condition.errors[:name], "has already been taken"
  end

  test "has many computers" do
    condition = computer_conditions(:original)
    assert_respond_to condition, :computers
  end

  test "cannot destroy when computers exist" do
    condition = computer_conditions(:original)
    assert_not condition.computers.empty?
    assert_not condition.destroy
    assert_includes condition.errors[:base], "Cannot delete record because dependent computers exist"
  end

  test "can destroy when no computers exist" do
    condition = ComputerCondition.create!(name: "Deletable Condition")
    assert condition.computers.empty?
    assert condition.destroy
  end
end
