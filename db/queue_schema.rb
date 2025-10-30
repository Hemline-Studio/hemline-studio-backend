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

ActiveRecord::Schema[8.0].define(version: 2025_10_24_074352) do
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

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_ide"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.string "business_image"
    t.string "business_image_public_id"
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
