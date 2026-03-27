# decor/app/models/computer_model.rb
# version 1.3
# v1.3 (Session 41): Appliances → Peripherals merger Phase 1.
#   Removed appliance: 1 from device_type enum. Enum is now hash form
#   { computer: 0, peripheral: 2 } to match the change in Computer#device_type.
#   DB data migration (device_type=1 → 2) was run manually before this session.
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

class ComputerModel < ApplicationRecord
  # Mirrors the device_type enum on Computer.
  # computer:   0 (default) — shown on the Computer Models admin page.
  # peripheral: 2           — for devices that attach to a host computer
  #                           (terminals, word-processors, storage controllers,
  #                            routers, etc.)
  #
  # Hash form is required because value 1 (formerly appliance) was removed in
  # Session 41, leaving a gap in the sequence. Rails needs the explicit mapping
  # { computer: 0, peripheral: 2 } to preserve the DB integer values.
  # Do NOT renumber peripheral to 1 — that would corrupt all existing DB records.
  enum :device_type, { computer: 0, peripheral: 2 }, prefix: true

  # A computer_model may be referenced by many computers (including peripherals,
  # which are stored in the computers table with device_type: peripheral).
  # restrict_with_error prevents deletion while any computers reference this model.
  has_many :computers, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
