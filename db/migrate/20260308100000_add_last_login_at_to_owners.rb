# decor/db/migrate/20260308100000_add_last_login_at_to_owners.rb
# version 1.0
# v1.0 (Session 20): Adds last_login_at (datetime, nullable) to the owners table.
#   Nullable — existing owners have no recorded login timestamp; NULL is displayed
#   as "—" in the admin UI. Stamped by SessionsController#create on every
#   successful login via update_column (no callbacks, no validations, fast).

class AddLastLoginAtToOwners < ActiveRecord::Migration[8.1]
  def change
    # Nullable — no default. Owners who have never logged in since this column
    # was added will show NULL, rendered as "—" in the admin owners table.
    add_column :owners, :last_login_at, :datetime
  end
end
