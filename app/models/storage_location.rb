# decor/app/models/storage_location.rb
# version 1.0
# Session A (Storage Locations feature, Part 1 of a 6-part session plan —
# see DECOR_PROJECT.md "Storage Locations Feature — Session Plan").
#
# A private, owner-defined physical storage location (e.g. "Attic Shelf 3").
# NOT a global/admin-managed lookup table (unlike ComponentType, SoftwareName,
# ComponentSuggestion) — each owner maintains their own independent list.
# Follows the same per-owner ownership pattern as ConnectionGroup, rather
# than the admin-managed reference-table pattern those other models use.
#
# DELIBERATELY NOT YET ADDED (deferred to Session C, once the FK columns
# exist on the referencing tables):
#   has_many :computers,      dependent: :nullify
#   has_many :components,     dependent: :nullify
#   has_many :software_items, dependent: :nullify
# Adding these now would generate SQL referencing storage_location_id columns
# that don't exist yet on computers/components/software_items until Session
# C's migration runs — left out of this session's model on purpose, not an
# oversight.
#
# Delete behaviour (confirmed in design consultation, to be wired up in
# Session C): destroying a StorageLocation must NULLIFY the storage_location_id
# on any Computer/Component/SoftwareItem that referenced it, never destroy
# those records themselves, and the owner-facing delete confirmation view
# must warn with counts before the destroy happens (see Session B).
#
# Privacy (confirmed in design consultation): storage_locations, and
# everything derived from it (the future storage_location_id fields on
# Computer/Component/SoftwareItem), must remain visible only to the owning
# owner — never shown on any owners_controller read-only view of another
# owner's collection, never exposed to other logged-in owners. Included in
# the admin-wide export only. See DECOR_PROJECT.md Session D ("Privacy
# Audit") for the dedicated verification pass.

class StorageLocation < ApplicationRecord
  belongs_to :owner

  validates :name, presence: true,
                    length: { maximum: 50 },
                    uniqueness: { scope: :owner_id,
                                  message: "is already used for another storage location of this owner" }
end
