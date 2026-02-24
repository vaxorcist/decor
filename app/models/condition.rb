# decor/app/models/condition.rb - version 1.1
# Added: has_many :components, dependent: :restrict_with_error
# Reason: components.condition_id FK points to this table; without this,
# deleting a condition referenced by a component would hit a raw DB exception
# rather than a friendly Rails validation error.
# NOTE: This has_many :components line will be REMOVED when the upcoming migration
# drops condition_id from components (replacing it with component_condition_id
# pointing to the new component_conditions table).

class Condition < ApplicationRecord
  has_many :computers, dependent: :restrict_with_error
  has_many :components, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
