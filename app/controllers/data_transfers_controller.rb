# decor/app/controllers/data_transfers_controller.rb
# version 1.4
# Session 37: Added connection_group_count to the import flash message.
#   When connection groups are imported the flash now shows e.g.
#   "Successfully imported 2 computer(s), 1 connection group(s)."
#   connection_group_count is included in the total-zero check (a file containing
#   only connection groups is a valid non-empty import).
# v1.3 (Session 28): Improved zero-import flash message ("Nothing to import —
#   all records already exist."). Split flash into per-device-type counts.
# v1.2 (Session 28): Separate computer_count / appliance_count / peripheral_count.
# v1.1 (Session 10): Added before_action :require_login.

class DataTransfersController < ApplicationController
  before_action :require_login

  # show — render the export/import landing page.
  def show
  end

  # export — generate a CSV of all the current owner's data (devices, components,
  # and connections) and stream it as a file attachment for download.
  def export
    csv      = OwnerExportService.export(Current.owner)
    filename = "decor_export_#{Current.owner.user_name}_#{Date.today}.csv"

    send_data csv,
      filename:    filename,
      type:        "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  # import — accept a CSV upload and delegate to OwnerImportService.
  # All database work runs inside a transaction in the service; on any error
  # the entire import (including any connection groups created in pass 3)
  # is rolled back atomically.
  def import
    file = params[:file]

    unless file.present?
      flash[:alert] = "Please select a CSV file to import."
      return redirect_to data_transfer_path
    end

    result = OwnerImportService.process(Current.owner, file)

    if result[:success]
      computer_count          = result[:computer_count].to_i
      appliance_count         = result[:appliance_count].to_i
      peripheral_count        = result[:peripheral_count].to_i
      component_count         = result[:component_count].to_i
      connection_group_count  = result[:connection_group_count].to_i

      total = computer_count + appliance_count + peripheral_count +
              component_count + connection_group_count

      if total == 0
        # All rows were skipped — everything already existed in the database
        # (or the file contained only comment rows).
        flash[:notice] = "Nothing to import — all records already exist."
      else
        # Build a readable summary, omitting zero-count categories.
        parts = []
        parts << "#{computer_count} computer(s)"              if computer_count          > 0
        parts << "#{appliance_count} appliance(s)"            if appliance_count         > 0
        parts << "#{peripheral_count} peripheral(s)"          if peripheral_count        > 0
        parts << "#{component_count} component(s)"            if component_count         > 0
        parts << "#{connection_group_count} connection group(s)" if connection_group_count > 0

        flash[:notice] = "Successfully imported #{parts.join(', ')}."
      end
    else
      flash[:alert] = "Import failed: #{result[:error]}"
    end

    redirect_to data_transfer_path
  end
end
