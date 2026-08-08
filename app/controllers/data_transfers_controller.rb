# decor/app/controllers/data_transfers_controller.rb
# version 1.7
# v1.7 (Storage Locations Session F — bug fix found via manual browser
#   check): build_success_message never included storage_location_count in
#   its `parts` list. OwnerImportService v1.13 added storage_location_count
#   to its result hash (Session F), but this method's hardcoded list of
#   count fields was never updated to match — same "single source of
#   truth / touch N places, miss one" shape as this session's earlier
#   all_owners_export_service.rb owner_part_number bug (see that file's
#   v1.2 header comment). Symptom: importing a CSV containing ONLY new
#   storage_location rows (or only computer/component/software rows whose
#   storage_location column auto-created a new location, with nothing else
#   new) silently fell through every `if count > 0` check to the final
#   "Nothing to import — all records already exist." branch, even though
#   OwnerImportService HAD created and saved the location(s).
#   Fixed by adding a storage_location_count line to `parts`, in the same
#   position OwnerExportService's own section ordering uses it (before
#   computer_count) — purely a display-order choice, no functional
#   significance. The exact same gap was found duplicated in
#   admin/data_transfers_controller.rb#build_success_message's
#   "owner_collection" case and fixed there in the same session (v1.4 ->
#   v1.5) — see that file's own changelog for detail.
#
# v1.6 (Session 49 — Session G): Partial-success support aligned with OwnerImportService v1.8.
#   Added software_item_count to the import result handling — was silently omitted in v1.5,
#   matching the same gap that existed in admin/data_transfers_controller v1.2 (fixed there
#   in v1.3, Session 48).
#   Added partial-success flash handling:
#     flash[:row_errors]   — per-row failures (rows that were skipped, not saved)
#     flash[:row_warnings] — per-row non-fatal notes (rows saved with caveat)
#   Extracted build_success_message private method (mirrors admin controller v1.3 pattern).
#   Updated import action comment — removed "atomically" and "rolled back" language since
#   OwnerImportService v1.8 saves each row independently; partial success is now possible.
#
# v1.5 (Session 42): Removed dead appliance_count code from import flash message builder.
# v1.4 (Session 37): Added connection_group_count to the import flash message.
# v1.3 (Session 28): Improved zero-import flash message. Split flash into per-device-type counts.
# v1.2 (Session 28): Separate computer_count / peripheral_count.
# v1.1 (Session 10): Added before_action :require_login.

class DataTransfersController < ApplicationController
  before_action :require_login

  # show — render the export/import landing page.
  def show
  end

  # export — generate a CSV of all the current owner's data (storage locations,
  # computers, peripherals, components, connections, and software items) and
  # stream it as a file attachment.
  def export
    csv      = OwnerExportService.export(Current.owner)
    filename = "decor_export_#{Current.owner.user_name}_#{Date.today}.csv"

    send_data csv,
      filename:    filename,
      type:        "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  # import — accept a CSV upload and delegate to OwnerImportService.
  # Each row is saved independently (OwnerImportService v1.8). Rows that fail a
  # required lookup or validation are collected in flash[:row_errors] and skipped;
  # rows saved with a non-fatal caveat (e.g. software saved as unattached when
  # the specified computer is not found) are in flash[:row_warnings].
  # flash[:notice] summarises the record counts that were saved.
  def import
    file = params[:file]

    unless file.present?
      flash[:alert] = "Please select a CSV file to import."
      return redirect_to data_transfer_path
    end

    result = OwnerImportService.process(Current.owner, file)

    if result[:success]
      flash[:notice]       = build_success_message(result)
      # Partial success: carry per-row issues to the view via flash.
      # flash[:row_errors]   — rows that were skipped (not saved)
      # flash[:row_warnings] — rows that were saved with a caveat
      flash[:row_errors]   = result[:row_errors]   if result[:row_errors]&.any?
      flash[:row_warnings] = result[:row_warnings] if result[:row_warnings]&.any?
    else
      flash[:alert] = "Import failed: #{result[:error]}"
    end

    redirect_to data_transfer_path
  end

  private

  # Builds the flash[:notice] message for a successful import.
  # Lists non-zero counts per record type. When some rows were skipped (partial
  # success), the notice lists what WAS saved; flash[:row_errors] carries the
  # per-row detail separately for display in the view.
  #
  # IMPORTANT: every count field OwnerImportService's result hash can return
  # MUST have a corresponding line here — see the v1.7 header comment above
  # for what happens when one is missed (a real import silently reports
  # "Nothing to import"). If OwnerImportService ever gains another counter,
  # add it here in the SAME change, not as a follow-up.
  def build_success_message(result)
    storage_location_count = result[:storage_location_count].to_i
    computer_count          = result[:computer_count].to_i
    peripheral_count        = result[:peripheral_count].to_i
    component_count         = result[:component_count].to_i
    connection_group_count  = result[:connection_group_count].to_i
    software_item_count     = result[:software_item_count].to_i
    skipped                 = result[:row_errors]&.size.to_i

    parts = []
    parts << "#{storage_location_count} storage location(s)" if storage_location_count > 0
    parts << "#{computer_count} computer(s)"                if computer_count         > 0
    parts << "#{peripheral_count} peripheral(s)"            if peripheral_count       > 0
    parts << "#{component_count} component(s)"              if component_count        > 0
    parts << "#{connection_group_count} connection(s)"      if connection_group_count > 0
    parts << "#{software_item_count} software item(s)"      if software_item_count    > 0

    if parts.any? && skipped > 0
      "Partially imported — saved #{parts.join(', ')}. " \
      "#{skipped} row(s) could not be imported (see details below)."
    elsif parts.any?
      "Successfully imported #{parts.join(', ')}."
    elsif skipped > 0
      "Import complete — no new records were added. " \
      "#{skipped} row(s) could not be imported (see details below)."
    else
      "Nothing to import — all records already exist."
    end
  end
end
