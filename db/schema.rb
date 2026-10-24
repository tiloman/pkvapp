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

ActiveRecord::Schema.define(version: 2026_10_24_100000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_integrations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.text "api_key_ciphertext"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id", "provider"], name: "index_ai_integrations_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_ai_integrations_on_user_id"
  end

  create_table "ai_local_settings", force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.string "base_url"
    t.string "model", default: "qwen2.5vl:7b", null: false
    t.text "api_key_ciphertext"
    t.text "allowed_emails"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "ai_runs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "operation_id"
    t.string "kind", null: false
    t.string "status", default: "processing", null: false
    t.string "provider"
    t.string "model"
    t.string "prompt_version"
    t.jsonb "output", default: {}, null: false
    t.jsonb "raw_response"
    t.jsonb "applied_changes", default: {}, null: false
    t.text "error_message"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.datetime "decided_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["operation_id"], name: "index_ai_runs_on_operation_id"
    t.index ["user_id", "status"], name: "index_ai_runs_on_user_id_and_status"
    t.index ["user_id"], name: "index_ai_runs_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "operations", force: :cascade do |t|
    t.string "title"
    t.float "value"
    t.boolean "insurance_paid", default: false
    t.boolean "insurance_submitted", default: false
    t.boolean "assistance_paid", default: false
    t.boolean "assistance_submitted", default: false
    t.datetime "billing_date"
    t.text "description"
    t.bigint "person_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "bill_deadline"
    t.float "insurance_payback"
    t.float "assistance_payback"
    t.string "aasm_state"
    t.boolean "paid", default: false
    t.string "todoist_item_id"
    t.index ["person_id"], name: "index_operations_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "color"
    t.string "ratio"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "todoist_integrations", force: :cascade do |t|
    t.bigint "user_id"
    t.string "token"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "project_id"
    t.index ["user_id"], name: "index_todoist_integrations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "mail_reminder"
    t.integer "remind_days_before"
    t.string "prefered_operations_view"
    t.datetime "ai_consented_at"
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_integrations", "users"
  add_foreign_key "ai_runs", "operations"
  add_foreign_key "ai_runs", "users"
end
