# decor/app/models/software_name.rb
# version 1.0
# Session 43: Part of the Software feature (Option C — full separation).
#   Admin-managed lookup table for software titles (e.g. VMS, RT-11, RSTS/E).
#   Analogous to ComponentType — stores the canonical name of a software
#   product together with an optional description.
#
#   restrict_with_error: a software name that has items referencing it cannot
#   be deleted. The admin must reassign or delete those items first. Matches
#   the ComputerModel restrict pattern.

class SoftwareName < ApplicationRecord
  # A software name is referenced by zero or more software items.
  # restrict_with_error prevents accidental deletion of a name that is in use.
  has_many :software_items, dependent: :restrict_with_error

  # name is the unique identifier for this software title.
  # Length enforced at both model (validation) and DB (CHECK constraint) levels.
  validates :name,
            presence:   true,
            uniqueness: true,
            length:     { maximum: 40 }

  # description is optional — provides context for the admin.
  validates :description, length: { maximum: 100 }, allow_blank: true
end
