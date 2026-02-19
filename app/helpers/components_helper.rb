# decor/app/helpers/components_helper.rb - version 1.1
# Added sort options: By Owner (A-Z) and By Type (A-Z)

module ComponentsHelper
  COMPONENT_SORT_OPTIONS = {
    added_desc: "Added (Newest First)",
    added_asc: "Added (Oldest First)",
    owner_asc: "By Owner (A-Z)",
    type_asc: "By Type (A-Z)"
  }.freeze

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
    [["Unassigned", "unassigned"]] + ComputerModel.order(:name).pluck(:name, :id)
  end

  def component_filter_computer_model_selected
    params[:computer_model]
  end
end
