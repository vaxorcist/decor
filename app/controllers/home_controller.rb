# decor/app/controllers/home_controller.rb
# version 1.1
# Session 51: Replaced unused @computer_count/@component_count/@owner_count with
#   three precise stats queries for the home page Statistics section.
#   @stat_owners:          SELECT COUNT(*) FROM owners
#   @stat_computers_total: SELECT COUNT(*) FROM computers WHERE device_type=0
#   @stat_computer_models: SELECT COUNT(DISTINCT computer_model_id) FROM computers WHERE device_type=0
#   Note: device_type=0 is the Computer enum value (peripheral=2 excluded).

class HomeController < ApplicationController
  def index
    # Total number of registered owners
    @stat_owners = Owner.count

    # Total number of computers (device_type: computer = 0).
    # Peripherals (device_type: peripheral = 2) are intentionally excluded.
    @stat_computers_total = Computer.where(device_type: 0).count

    # Number of distinct computer models represented across all computers.
    # Also limited to computers only (device_type=0), same as above.
    @stat_computer_models = Computer.where(device_type: 0).distinct.count(:computer_model_id)
  end
end
