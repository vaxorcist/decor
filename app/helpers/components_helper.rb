# decor/app/helpers/components_helper.rb
# version 1.5
# v1.5 (Session 88, Storage Locations feature Session E — see
#   DECOR_PROJECT.md "Storage Locations Feature — Session Plan"): Added the
#   Storage Location filter helper methods, following the exact pattern
#   established and pre-commit-verified for ComputersHelper v1.9:
#   component_filter_storage_locations_options — returns [[name, id], ...]
#     for Current.owner's OWN storage locations only, sorted by name.
#     Returns [] when not logged in (defensive — the filter block in
#     components/_filters.html.erb v1.5 is already gated by `if logged_in?`,
#     so this branch should never actually be exercised while logged out,
#     but the method stays safe to call regardless).
#   component_filter_storage_locations_selected — returns the current
#     storage_location_id param, or nil ("Any").
#   Storage locations are private per-owner data (confirmed design,
#   DECOR_PROJECT.md "Storage Locations Feature — Session Plan," privacy
#   audit passed Session D) — this is why the options list is always scoped
#   to Current.owner.storage_locations, never StorageLocation.all.
#   A crafted storage_location_id param belonging to a different owner is
#   NOT filtered out here (this helper only builds the dropdown) — that
#   defensive check lives in ComponentsController#index, matching the
#   Computers precedent exactly.
# v1.4 (Session 52): Split computer model filter into computer + peripheral.
#   component_filter_computer_model_options — now scoped to device_type: computer.
#   component_filter_peripheral_model_options — new; scoped to device_type: peripheral.
#   component_filter_peripheral_model_selected — new; reads params[:peripheral_model].
#   Matching changes: _filters.html.erb v1.2 (new Peripheral Model selector),
#   components_controller.rb v1.9 (new peripheral_model filter branch).
# v1.3 (Session 21): Added barter_status filter support.
#   COMPONENT_BARTER_STATUS_FILTER_OPTIONS — options for the barter status
#   filter selector in _filters.html.erb (members only).
#   component_filter_barter_status_options — returns the options array.
#   component_filter_barter_status_selected — returns current param or default "0+1".
# v1.2 (Session 19): Added sort option "By Order No. (A-Z)" (key: order_asc).
# v1.1: Added sort options: By Owner (A-Z) and By Type (A-Z).

module ComponentsHelper
  COMPONENT_SORT_OPTIONS = {
    added_desc: "Added (Newest First)",
    added_asc: "Added (Oldest First)",
    owner_asc: "By Owner (A-Z)",
    type_asc: "By Type (A-Z)",
    order_asc: "By Order No. (A-Z)"
  }.freeze

  # Barter status filter options for the index filter sidebar (members only).
  # Values are strings handled by a case/when in the controller:
  #   "0"   → WHERE barter_status = 0  (no trade only)
  #   "0+1" → WHERE barter_status IN (0, 1) (no trade + offered — the default)
  #   "1"   → WHERE barter_status = 1  (offered only)
  #   "2"   → WHERE barter_status = 2  (wanted only)
  COMPONENT_BARTER_STATUS_FILTER_OPTIONS = [
    ["No Trade + Offered", "0+1"],
    ["No Trade Only",      "0"],
    ["Offered Only",       "1"],
    ["Wanted Only",        "2"]
  ].freeze

  def component_sort_options
    COMPONENT_SORT_OPTIONS.map { |key, value| [value, key.to_s] }
  end

  def component_sort_selected
    if params[:sort].in? (COMPONENT_SORT_OPTIONS.keys.map(&:to_s))
      params[:sort]
    else
      "added_desc"
    end
  end

  def component_filter_component_type_options
    ComponentType.order(:name).pluck(:name, :id)
  end

  def component_filter_component_type_selected
    params[:component_type]
  end

  def component_filter_computer_model_options
    # Scoped to device_type: computer so peripheral models don't appear here.
    # "Unassigned" covers components not attached to any device (computer_id: nil).
    [["Unassigned", "unassigned"]] + ComputerModel.where(device_type: :computer).order(:name).pluck(:name, :id)
  end

  def component_filter_computer_model_selected
    params[:computer_model]
  end

  # Options for the Peripheral Model filter — scoped to device_type: peripheral.
  # No "Unassigned" entry here: the Computer Model filter already covers spares.
  def component_filter_peripheral_model_options
    ComputerModel.where(device_type: :peripheral).order(:name).pluck(:name, :id)
  end

  def component_filter_peripheral_model_selected
    params[:peripheral_model]
  end

  # Returns the options array for the barter status filter selector.
  def component_filter_barter_status_options
    COMPONENT_BARTER_STATUS_FILTER_OPTIONS
  end

  # Returns the currently selected barter status filter value.
  # Defaults to "0+1" when no param is present — this is the default filter
  # applied by the controller for logged-in users.
  def component_filter_barter_status_selected
    params[:barter_status].presence || "0+1"
  end

  # Returns [[name, id], ...] for Current.owner's OWN storage locations only,
  # sorted alphabetically by name. Used for the "Storage Location" filter
  # dropdown — see DECOR_PROJECT.md "Storage Locations Feature — Session Plan,"
  # Session E. Never returns another owner's storage locations: this is a
  # private, per-owner list (see storage_location.rb's own header comment and
  # the Session D privacy audit). Mirrors
  # ComputersHelper#computer_filter_storage_locations_options exactly.
  def component_filter_storage_locations_options
    return [] unless logged_in?

    Current.owner.storage_locations.order(:name).pluck(:name, :id)
  end

  # Returns the currently selected storage_location_id param, or nil ("Any").
  def component_filter_storage_locations_selected
    params[:storage_location_id]
  end
end
