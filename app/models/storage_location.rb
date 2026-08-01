# decor/app/models/storage_location.rb
# version 1.1
# Session C (Storage Locations feature, Part 3 of 6 — see DECOR_PROJECT.md
# "Storage Locations Feature — Session Plan"):
#   Added the three has_many associations deliberately deferred from
#   Session A, now that computers/components/software_items all carry a
#   storage_location_id column (migration 20260803000100):
#     has_many :computers,      dependent: :nullify
#     has_many :components,     dependent: :nullify
#     has_many :software_items, dependent: :nullify
#   dependent: :nullify (not :destroy or :restrict_with_error) per the
#   confirmed design consultation (Session 79): deleting a StorageLocation
#   must clear storage_location_id on anything that referenced it, never
#   destroy those records themselves. This is also what
#   StorageLocationsController#delete_confirm now counts (Session C) to
#   show the real "N computers / N components / N software items will be
#   set to no location" warning that Session B's interim, count-less
#   confirmation explicitly flagged as pending — see that controller
#   (v1.1) and its delete_confirm.html.erb (v1.1) for the completed
#   implementation.
#
# Session A (Storage Locations feature, Part 1 of 6):
#
# A private, owner-defined physical storage location (e.g. "Attic Shelf 3").
# NOT a global/admin-managed lookup table (unlike ComponentType, SoftwareName,
# ComponentSuggestion) — each owner maintains their own independent list.
# Follows the same per-owner ownership pattern as ConnectionGroup, rather
# than the admin-managed reference-table pattern those other models use.
#
# Privacy (confirmed in design consultation): storage_locations, and
# everything derived from it (storage_location_id on Computer/Component/
# SoftwareItem), must remain visible only to the owning owner — never shown
# on any owners_controller read-only view of another owner's collection,
# never exposed to other logged-in owners. Included in the admin-wide
# export only. See DECOR_PROJECT.md Session D ("Privacy Audit") for the
# dedicated verification pass — NOT done as part of this session; the
# view-level "own-view only" guards added this session to computers/
# components/software_items' show/index pages are a good-faith first pass
# consistent with that design, not a substitute for the dedicated audit
# Session D calls for.

class StorageLocation < ApplicationRecord
  belongs_to :owner

  has_many :computers,      dependent: :nullify
  has_many :components,     dependent: :nullify
  has_many :software_items, dependent: :nullify

  validates :name, presence: true,
                    length: { maximum: 50 },
                    uniqueness: { scope: :owner_id,
                                  message: "is already used for another storage location of this owner" }
end
