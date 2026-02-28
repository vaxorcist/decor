# decor/app/services/owner_export_service.rb
# version 1.0
# Service object that serialises all of an owner's computers and components
# into a CSV string suitable for download and later re-import.
#
# CSV format — one row per record, record type indicated by the first column:
#
#   record_type               "computer" or "component"
#   computer_model            model name (required for computer rows)
#   computer_order_number     order number of the computer (may be blank)
#   computer_serial_number    serial number of the computer; also used in component
#                             rows as the FK reference to the parent computer
#                             (blank = spare component, not attached to any computer)
#   computer_condition        condition name (may be blank)
#   computer_run_status       run status name (may be blank)
#   computer_history          history text (may be blank)
#   component_type            type name (required for component rows)
#   component_order_number    order number of the component (may be blank)
#   component_serial_number   serial number of the component (may be blank)
#   component_condition       condition value (may be blank)
#   component_description     description text (may be blank)
#
# Computer rows have blank values in all component_* columns.
# Component rows have blank values in computer_model / computer_order_number /
#   computer_condition / computer_run_status / computer_history columns.
#   computer_serial_number in a component row is the parent computer's serial (FK).
#
# Export order: all computers (sorted by model name, then serial number),
#   then all components (attached first sorted by computer serial then type name,
#   then spare components sorted by type name).

require "csv"

class OwnerExportService
  CSV_HEADERS = %w[
    record_type
    computer_model
    computer_order_number
    computer_serial_number
    computer_condition
    computer_run_status
    computer_history
    component_type
    component_order_number
    component_serial_number
    component_condition
    component_description
  ].freeze

  def initialize(owner)
    @owner = owner
  end

  # Convenience class method — matches the OwnerImportService.process interface.
  def self.export(owner)
    new(owner).to_csv
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << CSV_HEADERS
      export_computers(csv)
      export_components(csv)
    end
  end

  private

  def export_computers(csv)
    # Preload all associations so we don't hit N+1 queries.
    computers = @owner.computers
      .includes(:computer_model, :computer_condition, :run_status)
      .joins(:computer_model)
      .order("computer_models.name ASC", serial_number: :asc)

    computers.each do |computer|
      csv << [
        "computer",
        computer.computer_model.name,
        computer.order_number,
        computer.serial_number,
        computer.computer_condition&.name,
        computer.run_status&.name,
        computer.history,
        nil, nil, nil, nil, nil  # component columns left blank
      ]
    end
  end

  def export_components(csv)
    # Preload associations. Sort attached components before spares;
    # within each group sort by type name.
    components = @owner.components
      .includes(:component_type, :component_condition, computer: :computer_model)
      .joins(:component_type)
      .order(
        Arel.sql("CASE WHEN components.computer_id IS NULL THEN 1 ELSE 0 END ASC"),
        "component_types.name ASC"
      )

    components.each do |component|
      csv << [
        "component",
        nil,                                           # computer_model — blank for components
        nil,                                           # computer_order_number — blank
        component.computer&.serial_number,             # computer_serial_number = FK reference
        nil,                                           # computer_condition — blank
        nil,                                           # computer_run_status — blank
        nil,                                           # computer_history — blank
        component.component_type.name,
        component.order_number,
        component.serial_number,
        component.component_condition&.condition,      # ComponentCondition column is "condition"
        component.description
      ]
    end
  end
end
