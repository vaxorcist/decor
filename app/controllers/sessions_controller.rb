# decor/app/controllers/sessions_controller.rb
# version 1.1
# v1.1 (Session 20): Stamp last_login_at on successful login using update_column
#   so the timestamp is written directly to the DB without triggering callbacks
#   or validations (important: password_digest_changed? must not fire here).
# v1.0: Initial — login/logout with log_in/log_out helpers.

class SessionsController < ApplicationController
  before_action :require_logout, only: %i[new create]
  before_action :require_login, only: :destroy

  def new
  end

  def create
    owner = Owner.find_by("LOWER(user_name) = ?", params[:user_name]&.downcase)

    if owner&.authenticate(params[:password])
      # Stamp last login before log_in so the value is persisted even if
      # something unexpected happens later. update_column bypasses callbacks
      # and validations — safe here because we are only writing a timestamp.
      owner.update_column(:last_login_at, Time.current)
      log_in(owner)
      redirect_to root_path, notice: "Logged in successfully."
    else
      flash.now[:alert] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: "Logged out successfully."
  end
end
