# decor/app/models/software_condition.rb
# version 1.0
# Session 43: Part of the Software feature (Option C — full separation).
#   Admin-managed lookup table for software conditions.
#   Initial values: Complete, Incomplete, Subset.
#   Analogous to ComponentCondition but with its own distinct condition set —
#   software conditions are categorically different from hardware conditions
#   (Excellent / Good / Fair / For Parts). Full separation keeps both clean.
#
#   restrict_with_error: a condition in use cannot be deleted until all
#   referencing software_items are reassigned or removed.

class SoftwareCondition < ApplicationRecord
  has_many :software_items, dependent: :restrict_with_error

  # name is the displayed condition label (e.g. "Complete", "Subset").
  validates :name,
            presence:   true,
            uniqueness: true,
            length:     { maximum: 40 }

  # description is optional — explains what the condition means.
  validates :description, length: { maximum: 100 }, allow_blank: true
end
