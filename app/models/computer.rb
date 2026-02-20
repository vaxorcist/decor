# decor/app/models/computer.rb - version 1.2
# Renamed description to order_number
# Added length validation for order_number (max 20 characters)

class Computer < ApplicationRecord
  belongs_to :owner
  belongs_to :computer_model
  belongs_to :condition, optional: true
  belongs_to :run_status, optional: true
  has_many :components, dependent: :nullify

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
      .left_outer_joins(:condition, :run_status)
      .where(
        "LOWER(computer_models.name) LIKE LOWER(?) OR
         LOWER(owners.user_name) LIKE LOWER(?) OR
         LOWER(computers.serial_number) LIKE LOWER(?) OR
         LOWER(computers.order_number) LIKE LOWER(?) OR
         LOWER(computers.history) LIKE LOWER(?) OR
         LOWER(conditions.name) LIKE LOWER(?) OR
         LOWER(run_statuses.name) LIKE LOWER(?)",
        pattern, pattern, pattern, pattern, pattern, pattern, pattern
      )
      .distinct
  end
end
