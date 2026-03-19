# decor/app/controllers/admin/connection_types_controller.rb
# version 1.0
# Session 33: Part 2 — Admin ConnectionTypes CRUD.
# Mirrors Admin::ComponentTypesController pattern.
# ConnectionType has both :name (required, unique) and :label (optional).
# destroy uses restrict_with_error (has_many :connection_groups) — the return
# value is checked and a flash[:alert] is set on failure, per the project rule:
# "Always check the return value of destroy and redirect with flash[:alert]."

module Admin
  class ConnectionTypesController < BaseController
    before_action :set_connection_type, only: %i[edit update destroy]

    def index
      # includes(:connection_groups) avoids N+1 when rendering the groups count
      @connection_types = ConnectionType.order(:name).includes(:connection_groups)
    end

    def new
      @connection_type = ConnectionType.new
    end

    def create
      @connection_type = ConnectionType.new(connection_type_params)

      if @connection_type.save
        redirect_to admin_connection_types_path, notice: "Connection type was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @connection_type.update(connection_type_params)
        redirect_to admin_connection_types_path, notice: "Connection type was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # restrict_with_error means destroy returns false (and populates errors)
      # when connection_groups are present — handle both outcomes explicitly.
      if @connection_type.destroy
        redirect_to admin_connection_types_path, notice: "Connection type was successfully deleted."
      else
        redirect_to admin_connection_types_path,
                    alert: @connection_type.errors.full_messages.to_sentence
      end
    end

    private

    def set_connection_type
      @connection_type = ConnectionType.find(params[:id])
    end

    def connection_type_params
      params.require(:connection_type).permit(:name, :label)
    end
  end
end
