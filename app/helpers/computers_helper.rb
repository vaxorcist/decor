# decor/app/helpers/computers_helper.rb
# version 1.6
# v1.6 (Session 42): Replaced ["Appliance", "appliance"] with ["Peripheral", "peripheral"]
#   in COMPUTER_DEVICE_TYPE_FILTER_OPTIONS. The appliance enum value (device_type=1)
#   was removed in Session 41; the filter option was dead (would silently return
#   zero results). peripheral (device_type=2) is the correct replacement.
# v1.5 (Session 21): Added barter_status filter support.
#   COMPUTER_BARTER_STATUS_FILTER_OPTIONS — options for the barter status
#   filter selector in _filters.html.erb (members only).
#   computer_filter_barter_status_options — returns the options array.
#   computer_filter_barter_status_selected — returns current param or default "0+1".
#   The "0+1" value is a combined filter handled by the controller
#   (WHERE barter_status IN (0, 1)) — not a raw enum value.
# v1.4 (Session 20): Removed computer_form_device_type_options (dead code).
# v1.3 (Session 18): Added computer_form_device_type_options.
# v1.2 (Session 17): Added computer_filter_device_type_options/selected.
# v1.1: conditions → computer_conditions rename.

module ComputersHelper
  COMPUTER_SORT_OPTIONS = {
    added_desc: "Added (Newest First)",
    added_asc: "Added (Oldest First)",
    model_asc: "Model (A-Z)",
    model_desc: "Model (Z-A)"
  }.freeze

  # Device type options used by the index filter sidebar.
  # "Appliance" (device_type=1) was removed in Session 41 — peripheral replaces it.
  COMPUTER_DEVICE_TYPE_FILTER_OPTIONS = [
    ["Computer",   "computer"],
    ["Peripheral", "peripheral"]
  ].freeze

  # Barter status filter options for the index filter sidebar (members only).
  # Values are strings handled by a case/when in the controller:
  #   "0"   → WHERE barter_status = 0  (no trade only)
  #   "0+1" → WHERE barter_status IN (0, 1) (no trade + offered — the default)
  #   "1"   → WHERE barter_status = 1  (offered only)
  #   "2"   → WHERE barter_status = 2  (wanted only)
  COMPUTER_BARTER_STATUS_FILTER_OPTIONS = [
    ["No Trade + Offered", "0+1"],
    ["No Trade Only",      "0"],
    ["Offered Only",       "1"],
    ["Wanted Only",        "2"]
  ].freeze

  def computer_sort_options
    COMPUTER_SORT_OPTIONS.map { |key, value| [value, key.to_s] }
  end

  def computer_sort_selected
    if params[:sort].in?(COMPUTER_SORT_OPTIONS.keys.map(&:to_s))
      params[:sort]
    else
      "added_desc"
    end
  end

  def computer_filter_models_options
    ComputerModel.order(:name).pluck(:name, :id)
  end

  def computer_filter_models_selected
    params[:model]
  end

  def computer_filter_conditions_options
    ComputerCondition.order(:name).pluck(:name, :id)
  end

  def computer_filter_conditions_selected
    params[:computer_condition_id]
  end

  def computer_filter_run_statuses_options
    RunStatus.order(:name).pluck(:name, :id)
  end

  def computer_filter_run_statuses_selected
    params[:run_status_id]
  end

  # Returns the options array for the device_type filter selector.
  def computer_filter_device_type_options
    COMPUTER_DEVICE_TYPE_FILTER_OPTIONS
  end

  # Returns the currently selected device_type from params, or nil (→ "Any").
  def computer_filter_device_type_selected
    params[:device_type]
  end

  # Returns the options array for the barter status filter selector.
  def computer_filter_barter_status_options
    COMPUTER_BARTER_STATUS_FILTER_OPTIONS
  end

  # Returns the currently selected barter status filter value.
  # Defaults to "0+1" when no param is present — this is the default filter
  # applied by the controller for logged-in users.
  def computer_filter_barter_status_selected
    params[:barter_status].presence || "0+1"
  end
end
