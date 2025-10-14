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

ActiveRecord::Schema[8.0].define(version: 2025_10_14_162554) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "uuid-ossp"

  create_table "auth_codes", force: :cascade do |t|
    t.string "code"
    t.string "token"
    t.datetime "expires_at"
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["code"], name: "index_auth_codes_on_code", unique: true
    t.index ["token"], name: "index_auth_codes_on_token", unique: true
    t.index ["user_id"], name: "index_auth_codes_on_user_id"
  end

  create_table "client_custom_field_values", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.uuid "custom_field_id", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "custom_field_id"], name: "index_client_custom_field_values_unique", unique: true
    t.index ["client_id"], name: "index_client_custom_field_values_on_client_id"
    t.index ["custom_field_id"], name: "index_client_custom_field_values_on_custom_field_id"
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "gender", null: false
    t.string "measurement_unit", null: false
    t.boolean "in_trash", default: false
    t.string "phone_number"
    t.string "email"
    t.decimal "ankle", precision: 8, scale: 2
    t.decimal "bicep", precision: 8, scale: 2
    t.decimal "bottom", precision: 8, scale: 2
    t.decimal "chest", precision: 8, scale: 2
    t.decimal "head", precision: 8, scale: 2
    t.decimal "height", precision: 8, scale: 2
    t.decimal "hip", precision: 8, scale: 2
    t.decimal "inseam", precision: 8, scale: 2
    t.decimal "knee", precision: 8, scale: 2
    t.decimal "neck", precision: 8, scale: 2
    t.decimal "outseam", precision: 8, scale: 2
    t.decimal "shorts", precision: 8, scale: 2
    t.decimal "shoulder", precision: 8, scale: 2
    t.decimal "sleeve", precision: 8, scale: 2
    t.decimal "short_sleeve", precision: 8, scale: 2
    t.decimal "thigh", precision: 8, scale: 2
    t.decimal "top_length", precision: 8, scale: 2
    t.decimal "waist", precision: 8, scale: 2
    t.decimal "wrist", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["gender"], name: "index_clients_on_gender"
    t.index ["in_trash"], name: "index_clients_on_in_trash"
    t.index ["name"], name: "index_clients_on_name"
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "custom_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "field_name", null: false
    t.string "field_type", default: "measurement"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["is_active"], name: "index_custom_fields_on_is_active"
    t.index ["user_id"], name: "index_custom_fields_on_user_id"
  end

  create_table "folders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "image_ids", default: [], array: true
    t.string "cover_image"
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_ids"], name: "index_folders_on_image_ids", using: :gin
    t.index ["user_id", "name"], name: "index_folders_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "galleries", id: { type: :string, limit: 16 }, force: :cascade do |t|
    t.string "filename", null: false
    t.string "url", null: false
    t.string "public_id", null: false
    t.text "folder_ids", default: [], array: true
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_ids"], name: "index_galleries_on_folder_ids", using: :gin
    t.index ["public_id"], name: "index_galleries_on_public_id"
    t.index ["user_id", "public_id"], name: "index_galleries_on_user_id_and_public_id", unique: true
    t.index ["user_id"], name: "index_galleries_on_user_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "token", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["token"], name: "index_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "has_onboarded", default: false, null: false
    t.string "profession"
    t.string "business_name"
    t.text "business_address"
    t.string "skills", default: [], array: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["has_onboarded"], name: "index_users_on_has_onboarded"
    t.index ["profession"], name: "index_users_on_profession"
    t.index ["skills"], name: "index_users_on_skills", using: :gin
  end

  add_foreign_key "auth_codes", "users"
  add_foreign_key "client_custom_field_values", "clients"
  add_foreign_key "client_custom_field_values", "custom_fields"
  add_foreign_key "clients", "users"
  add_foreign_key "custom_fields", "users"
  add_foreign_key "folders", "users"
  add_foreign_key "galleries", "users"
  add_foreign_key "tokens", "users"
end
