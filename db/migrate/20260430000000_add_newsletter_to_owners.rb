# decor/db/migrate/20260430000000_add_newsletter_to_owners.rb
# version 1.0
# Session 56: Newsletter feature — adds newsletter preference column to owners.
#
# Column semantics: INTEGER NOT NULL DEFAULT 1
#   0 = owner has opted out of the newsletter
#   1 = owner receives the newsletter (default for all new and existing owners)
#
# Why add_column is safe here (no table recreation needed):
#   SQLite allows adding a column with a non-null default — it back-fills every
#   existing row with the default value (1) at the time of the migration.
#   This is one of the few ALTER TABLE operations SQLite supports natively.
#   No data migration step is needed: existing owners all start as subscribed.

class AddNewsletterToOwners < ActiveRecord::Migration[8.1]
  def change
    # default: 1 ensures all existing owners get "subscribed" automatically.
    # null: false enforces NOT NULL at the database level.
    add_column :owners, :newsletter, :integer, default: 1, null: false
  end
end
