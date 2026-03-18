# decor/app/models/connection_type.rb
# version 1.0
# Session 31: Part 1 — Connections feature foundation.
# Admin-managed lookup table for types of physical or logical connections between
# devices (e.g. "RS-232 Serial", "Ethernet", "UNIBUS", "Q-Bus").
# Follows the same pattern as ComponentType and RunStatus.

class ConnectionType < ApplicationRecord
  # A ConnectionType cannot be deleted while connection groups reference it.
  # Attempting deletion raises an ActiveRecord::DeleteRestrictionError with a
  # user-facing error message via restrict_with_error.
  has_many :connection_groups, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :label, length: { maximum: 100 }, allow_blank: true
end
