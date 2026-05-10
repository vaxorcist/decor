# decor/app/helpers/computer_statistics_helper.rb
# version 1.0
# v1.0 (Session 61): New helper — Computers Statistics page sort options.
#   Follows the same pattern as ComputersHelper (COMPUTER_SORT_OPTIONS constant,
#   _options and _selected helper methods).
#
#   Sort keys (string form, matches params[:sort]):
#     "most_common"  — count DESC, name A-Z for ties (the default)
#     "least_common" — count ASC,  name A-Z for ties
#     "model_asc"    — name A-Z
#     "model_desc"   — name Z-A

module ComputerStatisticsHelper
  COMPUTER_STATISTICS_SORT_OPTIONS = {
    most_common:  "Most Common",
    least_common: "Least Common",
    model_asc:    "Model A-Z",
    model_desc:   "Model Z-A"
  }.freeze

  # Returns the options array for the sort <select> element.
  # Format: [["Display label", "param_value"], ...]
  def computer_statistics_sort_options
    COMPUTER_STATISTICS_SORT_OPTIONS.map { |key, value| [value, key.to_s] }
  end

  # Returns the currently selected sort value.
  # Defaults to "most_common" when params[:sort] is absent or not a recognised key.
  def computer_statistics_sort_selected
    valid_keys = COMPUTER_STATISTICS_SORT_OPTIONS.keys.map(&:to_s)
    if params[:sort].in?(valid_keys)
      params[:sort]
    else
      "most_common"
    end
  end
end
