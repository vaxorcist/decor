# decor/app/helpers/computers_helper.rb
# version 1.2
# v1.2 (Session 17): Added computer_filter_device_type_options and
#   computer_filter_device_type_selected to support the new device_type
#   filter selector in _filters.html.erb.
# v1.1: conditions → computer_conditions rename (Session 7):
#   Condition.order(:name)   → ComputerCondition.order(:name)
#   params[:condition_id]    → params[:computer_condition_id]

module ComputersHelper
  COMPUTER_SORT_OPTIONS = {
    added_desc: "Added (Newest First)",
    added_asc: "Added (Oldest First)",
    model_asc: "Model (A-Z)",
    model_desc: "Model (Z-A)"
  }.freeze

  # Device type options for the filter selector.
  # Values are the enum string keys as used by ActiveRecord — Rails translates
  # these to the underlying integers when building the WHERE clause.
  # "appliance" label is a placeholder until the final UI name is confirmed.
  COMPUTER_DEVICE_TYPE_FILTER_OPTIONS = [
    ["Computer", "computer"],
    ["Appliance", "appliance"]
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

  # Returns the pre-built options array for the device_type filter selector.
  def computer_filter_device_type_options
    COMPUTER_DEVICE_TYPE_FILTER_OPTIONS
  end

  # Returns the currently selected device_type value from params, or nil
  # when no filter is active (which causes the "Any" blank option to be selected).
  def computer_filter_device_type_selected
    params[:device_type]
  end
end
