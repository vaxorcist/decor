# decor/db/migrate/20260306100000_create_site_texts.rb
# version 1.0
# Creates the site_texts table — stores named text pages (README, About, etc.)
# as markdown content in the database. Admins upload .md files via the admin UI;
# the rendered HTML is shown on the corresponding public page.
#
# key:     VARCHAR(40) — short identifier for the page ("readme", "about", etc.)
#          CHECK constraint enforces the length in SQLite (VARCHAR alone is cosmetic).
#          UNIQUE constraint ensures only one record per key.
# content: TEXT — full markdown content; length is unbounded by design.

class CreateSiteTexts < ActiveRecord::Migration[8.1]
  def change
    create_table :site_texts do |t|
      # key identifies which text page this row represents.
      # Kept short (40 chars) since it is an internal admin-controlled identifier,
      # not user-generated input.
      t.string :key,     null: false, limit: 40
      t.text   :content, null: false

      t.timestamps
    end

    # Enforce uniqueness at the DB level — one record per named page.
    add_index :site_texts, :key, unique: true

    # SQLite does not enforce VARCHAR(n) at runtime without a CHECK constraint.
    # The index above handles uniqueness; CHECK handles max length.
    # Rails' create_table DSL does not support inline CHECK constraints, so
    # we add it via raw SQL after the table is created.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TRIGGER site_texts_key_length_check
          BEFORE INSERT ON site_texts
          BEGIN
            SELECT RAISE(ABORT, 'site_texts.key exceeds 40 characters')
            WHERE length(NEW.key) > 40;
          END;
        SQL
        execute <<~SQL
          CREATE TRIGGER site_texts_key_length_check_update
          BEFORE UPDATE ON site_texts
          BEGIN
            SELECT RAISE(ABORT, 'site_texts.key exceeds 40 characters')
            WHERE length(NEW.key) > 40;
          END;
        SQL
      end
      dir.down do
        execute "DROP TRIGGER IF EXISTS site_texts_key_length_check"
        execute "DROP TRIGGER IF EXISTS site_texts_key_length_check_update"
      end
    end
  end
end
