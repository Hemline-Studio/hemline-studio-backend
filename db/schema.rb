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

ActiveRecord::Schema[8.0].define(version: 2025_11_16_131737) do
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
    t.string "gender", null: false
    t.string "measurement_unit", null: false
    t.boolean "in_trash", default: false
    t.string "phone_number"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.decimal "shoulder_width", precision: 10, scale: 2
    t.decimal "bust_chest", precision: 10, scale: 2
    t.decimal "round_underbust", precision: 10, scale: 2
    t.decimal "neck_circumference", precision: 10, scale: 2
    t.decimal "armhole_circumference", precision: 10, scale: 2
    t.decimal "sleeve_length", precision: 10, scale: 2
    t.decimal "round_sleeve_bicep", precision: 10, scale: 2
    t.decimal "elbow_circumference", precision: 10, scale: 2
    t.decimal "wrist_circumference", precision: 10, scale: 2
    t.decimal "top_length", precision: 10, scale: 2
    t.decimal "bust_point_nipple_to_nipple", precision: 10, scale: 2
    t.decimal "shoulder_to_bust_point", precision: 10, scale: 2
    t.decimal "shoulder_to_waist", precision: 10, scale: 2
    t.decimal "round_chest_upper_bust", precision: 10, scale: 2
    t.decimal "back_width", precision: 10, scale: 2
    t.decimal "back_length", precision: 10, scale: 2
    t.decimal "tommy_waist", precision: 10, scale: 2
    t.decimal "waist", precision: 10, scale: 2
    t.decimal "high_hip", precision: 10, scale: 2
    t.decimal "hip_full", precision: 10, scale: 2
    t.decimal "lap_thigh", precision: 10, scale: 2
    t.decimal "knee_circumference", precision: 10, scale: 2
    t.decimal "calf_circumference", precision: 10, scale: 2
    t.decimal "ankle_circumference", precision: 10, scale: 2
    t.decimal "skirt_length", precision: 10, scale: 2
    t.decimal "trouser_length_outseam", precision: 10, scale: 2
    t.decimal "inseam", precision: 10, scale: 2
    t.decimal "crotch_depth", precision: 10, scale: 2
    t.decimal "waist_to_hip", precision: 10, scale: 2
    t.decimal "waist_to_floor", precision: 10, scale: 2
    t.decimal "slit_height", precision: 10, scale: 2
    t.decimal "bust_apex_to_waist", precision: 10, scale: 2
    t.string "first_name"
    t.string "last_name"
    t.decimal "arm_length_full_three_quarter", precision: 10, scale: 2
    t.index ["gender"], name: "index_clients_on_gender"
    t.index ["in_trash"], name: "index_clients_on_in_trash"
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
    t.integer "folder_color", default: -> { "(floor(((random() * (9)::double precision) + (1)::double precision)))::integer" }, null: false
    t.boolean "is_public", default: false, null: false
    t.string "public_id"
    t.index ["image_ids"], name: "index_folders_on_image_ids", using: :gin
    t.index ["public_id"], name: "index_folders_on_public_id", unique: true
    t.index ["user_id", "name"], name: "index_folders_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_folders_on_user_id"
    t.check_constraint "folder_color >= 1 AND folder_color <= 9", name: "folder_color_range"
  end

  create_table "galleries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "file_name", null: false
    t.string "url", null: false
    t.string "public_id", null: false
    t.text "folder_ids", default: [], array: true
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "width"
    t.integer "height"
    t.string "aperture"
    t.string "camera_model"
    t.string "shutter_speed"
    t.integer "iso"
    t.index ["folder_ids"], name: "index_galleries_on_folder_ids", using: :gin
    t.index ["public_id"], name: "index_galleries_on_public_id"
    t.index ["user_id", "public_id"], name: "index_galleries_on_user_id_and_public_id", unique: true
    t.index ["user_id"], name: "index_galleries_on_user_id"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.uuid "user_id", null: false
    t.string "item", null: false
    t.integer "quantity", default: 1, null: false
    t.text "notes"
    t.boolean "is_done", default: false, null: false
    t.datetime "due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_orders_on_client_id"
    t.index ["due_date"], name: "index_orders_on_due_date"
    t.index ["is_done"], name: "index_orders_on_is_done"
    t.index ["user_id", "client_id"], name: "index_orders_on_user_id_and_client_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "token", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "token_type", default: "access", null: false
    t.index ["token"], name: "index_tokens_on_token", unique: true
    t.index ["user_id", "token_type"], name: "index_tokens_on_user_id_and_token_type"
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
    t.string "business_image"
    t.string "business_image_public_id"
    t.string "phone_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["has_onboarded"], name: "index_users_on_has_onboarded"
    t.index ["profession"], name: "index_users_on_profession"
    t.index ["skills"], name: "index_users_on_skills", using: :gin
  end

  create_table "waitlists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_waitlists_on_email", unique: true
  end

  add_foreign_key "auth_codes", "users"
  add_foreign_key "client_custom_field_values", "clients"
  add_foreign_key "client_custom_field_values", "custom_fields"
  add_foreign_key "clients", "users"
  add_foreign_key "custom_fields", "users"
  add_foreign_key "folders", "users"
  add_foreign_key "galleries", "users"
  add_foreign_key "orders", "clients"
  add_foreign_key "orders", "users"
  add_foreign_key "tokens", "users"
end
