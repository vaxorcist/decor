# decor/app/models/component_condition.rb
# version 1.1
# Added: validates :condition — presence (non-blank) and uniqueness (case-insensitive).
# Without these, blank strings saved successfully and duplicate values raised a raw
# SQLite3::ConstraintException instead of a clean ActiveRecord validation error.
# The DB still enforces UNIQUE NOT NULL as a safety net (defense-in-depth), but
# the model validation ensures user-friendly error messages and correct controller
# behaviour (re-render form with 422 on failure).

class ComponentCondition < ApplicationRecord
  has_many :components, dependent: :restrict_with_error

  # :condition is the value column (not :name) — intentional design from Session 7.
  # case_sensitive: false matches the convention used for ComputerCondition.
  validates :condition, presence: true, uniqueness: { case_sensitive: false }
end
