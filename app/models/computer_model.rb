# decor/app/models/computer_model.rb
# version 1.1
# Added device_type enum (computer: 0, appliance: 1) so that models can be
# categorised as belonging to the computers list or the appliances list.
# Prefix: true generates device_type_computer? / device_type_appliance? predicates
# and Computer.device_type_computer / .device_type_appliance scopes.

class ComputerModel < ApplicationRecord
  # Mirrors the device_type enum on Computer.
  # computer: 0 (default) — shown on the Computer Models admin page.
  # appliance: 1           — shown on the Appliance Models admin page.
  enum :device_type, { computer: 0, appliance: 1 }, prefix: true

  # A computer_model may be referenced by many computers (including appliances,
  # which are stored in the computers table with device_type: :appliance).
  # restrict_with_error prevents deletion while any computers reference this model.
  has_many :computers, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
