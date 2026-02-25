# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_25_120000) do
  create_table "component_conditions", force: :cascade do |t|
    t.string "condition", limit: 40, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["condition"], name: "index_component_conditions_on_condition", unique: true
  end

  create_table "component_types", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", limit: 40, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_component_types_on_name", unique: true
  end

  create_table "components", force: :cascade do |t|
    t.integer "component_condition_id"
    t.integer "component_type_id", null: false
    t.integer "computer_id"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.text "history"
    t.string "order_number", limit: 20
    t.integer "owner_id", null: false
    t.string "serial_number", limit: 20
    t.datetime "updated_at", precision: nil, null: false
    t.index ["component_condition_id"], name: "index_components_on_component_condition_id"
    t.index ["component_type_id"], name: "index_components_on_component_type_id"
    t.index ["computer_id"], name: "index_components_on_computer_id"
    t.index ["owner_id"], name: "index_components_on_owner_id"
  end

  create_table "computer_conditions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_computer_conditions_on_name", unique: true
  end

  create_table "computer_models", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", limit: 40, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_computer_models_on_name", unique: true
  end

  create_table "computers", force: :cascade do |t|
    t.integer "computer_condition_id"
    t.integer "computer_model_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "history"
    t.string "order_number", limit: 20
    t.integer "owner_id", null: false
    t.integer "run_status_id"
    t.string "serial_number", limit: 20, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["computer_condition_id"], name: "index_computers_on_computer_condition_id"
    t.index ["computer_model_id"], name: "index_computers_on_computer_model_id"
    t.index ["owner_id"], name: "index_computers_on_owner_id"
    t.index ["run_status_id"], name: "index_computers_on_run_status_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "reminder_sent_at"
    t.datetime "sent_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invites_on_email"
    t.index ["token"], name: "index_invites_on_token", unique: true
  end

  create_table "owners", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "country"
    t.string "country_visibility", limit: 20
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.string "email_visibility", limit: 20
    t.string "password_digest"
    t.string "real_name", limit: 40
    t.string "real_name_visibility", limit: 20
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_name", limit: 15
    t.string "website"
    t.index ["country"], name: "index_owners_on_country"
    t.index ["country_visibility"], name: "index_owners_on_country_visibility"
    t.index ["email"], name: "index_owners_on_email", unique: true
    t.index ["email_visibility"], name: "index_owners_on_email_visibility"
    t.index ["real_name_visibility"], name: "index_owners_on_real_name_visibility"
    t.index ["reset_password_token"], name: "index_owners_on_reset_password_token", unique: true
    t.index ["user_name"], name: "index_owners_on_user_name", unique: true
  end

  create_table "run_statuses", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", limit: 40
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_run_statuses_on_name", unique: true
  end

  add_foreign_key "components", "component_conditions"
  add_foreign_key "components", "component_types"
  add_foreign_key "components", "computers"
  add_foreign_key "components", "owners"
  add_foreign_key "computers", "computer_conditions"
  add_foreign_key "computers", "computer_models"
  add_foreign_key "computers", "owners"
  add_foreign_key "computers", "run_statuses"
end
