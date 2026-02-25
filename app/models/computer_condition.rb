# decor/app/models/computer_condition.rb
# version 1.1
# Added missing model validations (name presence + uniqueness) that the test
# suite requires. These were present in the original condition.rb but omitted
# from v1.0 of this file.
# Changed computers association to dependent: :restrict_with_error — matches
# the original condition.rb behaviour and the expectations of the test suite.
# Replacing: decor/app/models/condition.rb (that file should be deleted)

class ComputerCondition < ApplicationRecord
  # A computer_condition record cannot be deleted while any computer references
  # it. The admin must reassign or clear those computers first.
  has_many :computers, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
