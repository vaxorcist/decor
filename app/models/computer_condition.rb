# decor/app/models/computer_condition.rb
# version 1.2
# Changed uniqueness validation to case_sensitive: false — matches
# ComponentCondition and prevents "Working" / "working" coexisting.

class ComputerCondition < ApplicationRecord
  # A computer_condition record cannot be deleted while any computer references
  # it. The admin must reassign or clear those computers first.
  has_many :computers, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
