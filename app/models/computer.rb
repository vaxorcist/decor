# decor/app/models/computer.rb
# version 1.4
# Changed: has_many :components, dependent: :nullify → dependent: :destroy
# Rationale: deleting a computer now cascades and destroys all its components.
# The database-level ON DELETE CASCADE will be added in a later migration;
# this Rails-level dependent: :destroy is the application-layer enforcement
# that is in effect until then.

class Computer < ApplicationRecord
  belongs_to :owner
  belongs_to :computer_model
  belongs_to :computer_condition, optional: true
  belongs_to :run_status, optional: true
  has_many :components, dependent: :destroy

  # Validations
  validates :serial_number, presence: true
  validates :order_number, length: { maximum: 20 }, allow_blank: true

  # Search scope that searches across model name, owner name, serial number, order_number, and history
  # Supports SQL wildcards (% for any characters, _ for single character)
  # Case-insensitive search
  scope :search, ->(query) do
    return all if query.blank?

    # SQL LIKE pattern - user can include their own wildcards or we wrap the whole thing
    pattern = query.include?("%") || query.include?("_") ? query : "%#{query}%"

    # Search in: computer model name, owner username, serial number, order_number, history
    joins(:owner, :computer_model)
      .left_outer_joins(:computer_condition, :run_status)
      .where(
        "LOWER(computer_models.name) LIKE LOWER(?) OR
         LOWER(owners.user_name) LIKE LOWER(?) OR
         LOWER(computers.serial_number) LIKE LOWER(?) OR
         LOWER(computers.order_number) LIKE LOWER(?) OR
         LOWER(computers.history) LIKE LOWER(?) OR
         LOWER(computer_conditions.name) LIKE LOWER(?) OR
         LOWER(run_statuses.name) LIKE LOWER(?)",
        pattern, pattern, pattern, pattern, pattern, pattern, pattern
      )
      .distinct
  end
end
