# decor/app/helpers/software_items_helper.rb
# version 1.1
# v1.1 (Session 88, Storage Locations feature Session E — see
#   DECOR_PROJECT.md "Storage Locations Feature — Session Plan"): Added the
#   Storage Location filter helper methods, following the exact pattern
#   established and pre-commit-verified for ComputersHelper v1.9:
#   software_item_filter_storage_locations_options — returns [[name, id], ...]
#     for Current.owner's OWN storage locations only, sorted by name.
#     Returns [] when not logged in (defensive — the filter block in
#     software_items/_filters.html.erb v1.1 is already gated by
#     `if logged_in?`, so this branch should never actually be exercised
#     while logged out, but the method stays safe to call regardless).
#   software_item_filter_storage_locations_selected — returns the current
#     storage_location_id param, or nil ("Any").
#   Storage locations are private per-owner data (confirmed design,
#   DECOR_PROJECT.md "Storage Locations Feature — Session Plan," privacy
#   audit passed Session D) — this is why the options list is always scoped
#   to Current.owner.storage_locations, never StorageLocation.all.
#   A crafted storage_location_id param belonging to a different owner is
#   NOT filtered out here (this helper only builds the dropdown) — that
#   defensive check lives in SoftwareItemsController#index, matching the
#   Computers precedent exactly.
# v1.0 (Session 50): New file — sort options and filter helpers for the
#   public /software_items index page (added in this session alongside the
#   _filters.html.erb partial and controller v1.3).
#
# Sort options (6 choices):
#   Default: name_asc_version_asc — Software (A-Z) and Version (A-Z).
#
# Filter helpers:
#   software_item_filter_software_name_options — distinct SoftwareNames that have
#     items, sorted by name A-Z.
#   software_item_filter_owner_options — distinct Owners that have items, sorted
#     by user_name A-Z.
#   software_item_filter_barter_status_options — barter status filter (logged-in
#     members only); options identical to those on computers and components pages.
#
# Follows the pattern established in ComputersHelper (v1.9).

module SoftwareItemsHelper
  # Sort options keyed by the param string the controller receives in params[:sort].
  # Hash order determines the order of <option> elements in the dropdown.
  # Default (no param) → "name_asc_version_asc" — handled in the controller else branch.
  SOFTWARE_ITEM_SORT_OPTIONS = {
    "name_asc_version_asc"            => "Software (A-Z) and Version (A-Z)",
    "name_desc_version_asc"           => "Software (Z-A) and Version (A-Z)",
    "added_desc"                      => "Added (Newest First)",
    "added_asc"                       => "Added (Oldest First)",
    "owner_asc_name_asc_version_asc"  => "Owner (A-Z), Software (A-Z) and Version (A-Z)",
    "owner_asc_name_desc_version_asc" => "Owner (A-Z), Software (Z-A) and Version (A-Z)"
  }.freeze

  # Barter status filter options (members only).
  # Values are strings handled by a case/when in the controller:
  #   "0"   → WHERE barter_status = 0  (no trade only)
  #   "0+1" → WHERE barter_status IN (0, 1) (no trade + offered — the default)
  #   "1"   → WHERE barter_status = 1  (offered only)
  #   "2"   → WHERE barter_status = 2  (wanted only)
  SOFTWARE_ITEM_BARTER_STATUS_FILTER_OPTIONS = [
    ["No Trade + Offered", "0+1"],
    ["No Trade Only",      "0"],
    ["Offered Only",       "1"],
    ["Wanted Only",        "2"]
  ].freeze

  # Returns [[label, value], ...] pairs for the sort select box.
  def software_item_sort_options
    SOFTWARE_ITEM_SORT_OPTIONS.map { |key, label| [label, key] }
  end

  # Returns the currently selected sort key, or the default if none is set.
  # The default "name_asc_version_asc" matches the controller's else branch.
  def software_item_sort_selected
    if SOFTWARE_ITEM_SORT_OPTIONS.key?(params[:sort])
      params[:sort]
    else
      "name_asc_version_asc"
    end
  end

  # Returns [[name, id], ...] for SoftwareNames that have at least one item,
  # sorted alphabetically by name. Used for the "Software" filter dropdown.
  def software_item_filter_software_name_options
    SoftwareName.joins(:software_items).distinct.order(:name).pluck(:name, :id)
  end

  # Returns the currently selected software_name_id param, or nil (→ "Any").
  def software_item_filter_software_name_selected
    params[:software_name_id]
  end

  # Returns [[user_name, id], ...] for Owners that have at least one software item,
  # sorted alphabetically by user_name. Used for the "Owner" filter dropdown.
  def software_item_filter_owner_options
    Owner.joins(:software_items).distinct.order(:user_name).pluck(:user_name, :id)
  end

  # Returns the currently selected owner_id param, or nil (→ "Any").
  def software_item_filter_owner_selected
    params[:owner_id]
  end

  # Returns the options array for the barter status filter selector.
  def software_item_filter_barter_status_options
    SOFTWARE_ITEM_BARTER_STATUS_FILTER_OPTIONS
  end

  # Returns the current barter status filter value.
  # Defaults to "0+1" when no param is present — the same default applied by the
  # controller for logged-in users (hides "wanted" items from the default view).
  def software_item_filter_barter_status_selected
    params[:barter_status].presence || "0+1"
  end

  # Returns [[name, id], ...] for Current.owner's OWN storage locations only,
  # sorted alphabetically by name. Used for the "Storage Location" filter
  # dropdown — see DECOR_PROJECT.md "Storage Locations Feature — Session Plan,"
  # Session E. Never returns another owner's storage locations: this is a
  # private, per-owner list (see storage_location.rb's own header comment and
  # the Session D privacy audit). Mirrors
  # ComputersHelper#computer_filter_storage_locations_options exactly.
  def software_item_filter_storage_locations_options
    return [] unless logged_in?

    Current.owner.storage_locations.order(:name).pluck(:name, :id)
  end

  # Returns the currently selected storage_location_id param, or nil ("Any").
  def software_item_filter_storage_locations_selected
    params[:storage_location_id]
  end
end
