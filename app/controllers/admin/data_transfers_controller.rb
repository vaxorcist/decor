# decor/app/controllers/admin/data_transfers_controller.rb
# version 1.2
# v1.2 (Session 41): Appliances → Peripherals merger Phase 4.
#   Removed "appliance_models" from both build_export and process_import —
#   the admin Appliance Models route and page are gone; there is no UI path
#   that sends data_type: "appliance_models" any more.
#   Removed "appliance(s)" line from build_success_message for owner_collection —
#   OwnerImportService v1.5 no longer returns :appliance_count (legacy appliance
#   rows are now silently mapped to peripheral on import).
# v1.1 (Session 29): Added "peripheral_models" data_type. Fixed owner_collection
#   success message to show per-type counts.

require "csv"

module Admin
  class DataTransfersController < BaseController
    before_action :load_owners, only: [:show]

    def show
    end

    def export
      data_type = params[:data_type].presence
      owner_id  = params[:owner_id].presence

      unless data_type.present?
        flash[:alert] = "Please select a data type to export."
        return redirect_to admin_data_transfer_path
      end

      csv, filename = build_export(data_type, owner_id)

      if csv.nil?
        flash[:alert] = export_validation_error(data_type, owner_id)
        return redirect_to admin_data_transfer_path
      end

      send_data csv,
        filename:    filename,
        type:        "text/csv; charset=utf-8",
        disposition: "attachment"
    end

    def import
      data_type = params[:data_type].presence
      owner_id  = params[:owner_id].presence
      file      = params[:file]

      unless data_type.present?
        flash[:alert] = "Please select a data type to import."
        return redirect_to admin_data_transfer_path
      end

      unless file.present?
        flash[:alert] = "Please select a CSV file to import."
        return redirect_to admin_data_transfer_path
      end

      result = process_import(data_type, owner_id, file)

      if result[:success]
        flash[:notice] = build_success_message(data_type, result)
      else
        flash[:alert] = "Import failed: #{result[:error]}"
      end

      redirect_to admin_data_transfer_path
    end

    private

    def load_owners
      @owners = Owner.order(:user_name)
    end

    # ── Export helpers ─────────────────────────────────────────────────────

    def build_export(data_type, owner_id)
      case data_type
      when "computer_models"
        csv      = ComputerModelExportService.export(device_type: :computer)
        filename = "computer_models_#{Date.today}.csv"

      # Peripheral models covers all device_type_peripheral? records —
      # former appliance models were merged into this category in Session 41.
      when "peripheral_models"
        csv      = ComputerModelExportService.export(device_type: :peripheral)
        filename = "peripheral_models_#{Date.today}.csv"

      when "component_types"
        csv      = ComponentTypeExportService.export
        filename = "component_types_#{Date.today}.csv"

      when "owner_collection"
        if owner_id == "all"
          csv      = AllOwnersExportService.export
          filename = "all_owners_#{Date.today}.csv"
        elsif owner_id.present?
          owner = Owner.find_by(id: owner_id)
          return [nil, nil] unless owner

          csv      = OwnerExportService.export(owner)
          filename = "decor_export_#{owner.user_name}_#{Date.today}.csv"
        else
          return [nil, nil]
        end

      else
        return [nil, nil]
      end

      [csv, filename]
    end

    def export_validation_error(data_type, owner_id)
      if data_type == "owner_collection" && owner_id.blank?
        "Please select an owner (or All Owners) when exporting Owner Collection Data."
      else
        "Unknown data type. Please select a valid option."
      end
    end

    # ── Import helpers ──────────────────────────────────────────────────────

    def process_import(data_type, owner_id, file)
      case data_type
      when "computer_models"
        ComputerModelImportService.process(file, device_type: :computer)

      # Peripheral models covers all device_type_peripheral? records.
      when "peripheral_models"
        ComputerModelImportService.process(file, device_type: :peripheral)

      when "component_types"
        ComponentTypeImportService.process(file)

      when "owner_collection"
        unless owner_id.present?
          return { success: false, error: "Please select an owner to import into." }
        end

        owner = Owner.find_by(id: owner_id)
        unless owner
          return { success: false, error: "Owner not found." }
        end

        OwnerImportService.process(owner, file)

      else
        { success: false, error: "Unknown data type '#{data_type}'." }
      end
    end

    def build_success_message(data_type, result)
      case data_type
      when "computer_models"
        "Successfully imported #{result[:count]} computer model(s)."
      when "peripheral_models"
        "Successfully imported #{result[:count]} peripheral model(s)."
      when "component_types"
        "Successfully imported #{result[:count]} component type(s)."
      when "owner_collection"
        # Build a list of non-zero counts; omit device types with zero imported.
        # OwnerImportService v1.5 returns: computer_count, peripheral_count,
        # component_count. Legacy appliance rows are now mapped to peripheral.
        parts = []
        parts << "#{result[:computer_count]} computer(s)"     if result[:computer_count].to_i   > 0
        parts << "#{result[:peripheral_count]} peripheral(s)" if result[:peripheral_count].to_i > 0
        parts << "#{result[:component_count]} component(s)"   if result[:component_count].to_i  > 0

        if parts.any?
          "Successfully imported #{parts.join(', ')}."
        else
          "Nothing to import — all records already exist."
        end
      else
        "Import complete."
      end
    end
  end
end
