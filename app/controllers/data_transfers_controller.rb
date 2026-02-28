# decor/app/controllers/data_transfers_controller.rb - version 1.1
# Added: before_action :require_login (was missing — all three actions were
# reachable without authentication).
# require_login is defined in Authentication concern and redirects to
# new_session_path when Current.owner is nil.

class DataTransfersController < ApplicationController
  before_action :require_login

  # show — render the export/import landing page.
  def show
  end

  # export — generate a CSV of all the current owner's computers and components
  # and stream it as a file attachment for immediate download.
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
  # the entire import is rolled back atomically.
  def import
    file = params[:file]

    unless file.present?
      flash[:alert] = "Please select a CSV file to import."
      return redirect_to data_transfer_path
    end

    result = OwnerImportService.process(Current.owner, file)

    if result[:success]
      flash[:notice] = "Successfully imported #{result[:computer_count]} computer(s) " \
                       "and #{result[:component_count]} component(s)."
    else
      flash[:alert] = "Import failed: #{result[:error]}"
    end

    redirect_to data_transfer_path
  end
end
