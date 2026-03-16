# decor/app/models/computer_model.rb
# version 1.2
# v1.2 (Session 25): Added peripheral: 2 to device_type enum.
#   Mirrors the change made to Computer#device_type in computer.rb v1.7.
#   The computers/_form.html.erb model selector scopes to
#   ComputerModel.where(device_type: computer.device_type) — without this
#   value the query returned an empty result set for device_type: "peripheral",
#   leaving the Model select blank on the new/edit peripheral form.
#   A CHECK(device_type IN (0,1,2)) constraint migration for this table is
#   pending (noted in migration 20260316100000).
# v1.1: Added device_type enum (computer: 0, appliance: 1) so that models can
#   be categorised as belonging to the computers list or the appliances list.
#   Prefix: true generates device_type_computer? / device_type_appliance? predicates
#   and ComputerModel.device_type_computer / .device_type_appliance scopes.

class ComputerModel < ApplicationRecord
  # Mirrors the device_type enum on Computer.
  # computer:    0 (default) — shown on the Computer Models admin page.
  # appliance:   1           — shown on the Appliance Models admin page.
  # peripheral:  2           — for devices that attach to a host computer
  #                            (terminals, word-processors, storage controllers).
  enum :device_type, { computer: 0, appliance: 1, peripheral: 2 }, prefix: true

  # A computer_model may be referenced by many computers (including appliances
  # and peripherals, which are all stored in the computers table with the
  # appropriate device_type value).
  # restrict_with_error prevents deletion while any computers reference this model.
  has_many :computers, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
