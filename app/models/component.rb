# decor/app/models/component.rb
# version 1.2
# Updated association: belongs_to :condition (→ conditions table) removed.
# Replaced with belongs_to :component_condition (→ component_conditions table).
# The new association is optional — existing components have no condition set.

class Component < ApplicationRecord
  belongs_to :owner
  belongs_to :computer, optional: true
  belongs_to :component_type
  belongs_to :component_condition, optional: true

  # Search scope that searches across component type, owner name, computer model, and description
  # Supports SQL wildcards (% for any characters, _ for single character)
  # Case-insensitive search
  scope :search, ->(query) do
    return all if query.blank?

    # SQL LIKE pattern - user can include their own wildcards or we wrap the whole thing
    pattern = query.include?("%") || query.include?("_") ? query : "%#{query}%"

    # Search in: component type name, owner username, computer model name, description
    joins(:owner, :component_type)
      .left_outer_joins(computer: :computer_model)
      .where(
        "LOWER(component_types.name) LIKE LOWER(?) OR
         LOWER(owners.user_name) LIKE LOWER(?) OR
         LOWER(computer_models.name) LIKE LOWER(?) OR
         LOWER(components.description) LIKE LOWER(?)",
        pattern, pattern, pattern, pattern
      )
      .distinct
  end
end
