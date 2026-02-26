# decor/app/helpers/computers_helper.rb
# version 1.1
# Updated following the conditions → computer_conditions rename (Session 7):
#   Condition.order(:name)   → ComputerCondition.order(:name)
#   params[:condition_id]    → params[:computer_condition_id]

module ComputersHelper
  COMPUTER_SORT_OPTIONS = {
    added_desc: "Added (Newest First)",
    added_asc: "Added (Oldest First)",
    model_asc: "Model (A-Z)",
    model_desc: "Model (Z-A)"
  }.freeze

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
end
