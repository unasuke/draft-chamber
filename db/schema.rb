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

ActiveRecord::Schema[8.1].define(version: 2026_02_11_090022) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "document_material_uploaded_bies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "document_material_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["document_material_id"], name: "index_document_material_uploaded_bies_on_document_material_id"
    t.index ["user_id"], name: "index_document_material_uploaded_bies_on_user_id"
  end

  create_table "document_materials", force: :cascade do |t|
    t.integer "byte_size"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.text "download_error"
    t.string "download_status", default: "pending", null: false
    t.datetime "downloaded_at"
    t.string "filename"
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_materials_on_document_id", unique: true
    t.index ["download_status"], name: "index_document_materials_on_download_status"
  end

  create_table "documents", force: :cascade do |t|
    t.text "abstract"
    t.datetime "created_at", null: false
    t.string "document_type"
    t.datetime "expires"
    t.integer "group_id"
    t.string "name", null: false
    t.integer "pages"
    t.string "resource_uri", null: false
    t.string "rev"
    t.datetime "time"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "uploaded_filename"
    t.index ["document_type"], name: "index_documents_on_document_type"
    t.index ["group_id"], name: "index_documents_on_group_id"
    t.index ["name"], name: "index_documents_on_name", unique: true
    t.index ["resource_uri"], name: "index_documents_on_resource_uri", unique: true
  end

  create_table "github_authentications", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "nickname", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["uid"], name: "index_github_authentications_on_uid", unique: true
    t.index ["user_id"], name: "index_github_authentications_on_user_id", unique: true
  end

  create_table "groups", force: :cascade do |t|
    t.string "acronym", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "group_type"
    t.string "list_archive"
    t.string "list_email"
    t.string "name"
    t.integer "parent_id"
    t.string "resource_uri", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["acronym"], name: "index_groups_on_acronym", unique: true
    t.index ["group_type"], name: "index_groups_on_group_type"
    t.index ["parent_id"], name: "index_groups_on_parent_id"
    t.index ["resource_uri"], name: "index_groups_on_resource_uri", unique: true
    t.index ["state"], name: "index_groups_on_state"
  end

  create_table "meetings", force: :cascade do |t|
    t.integer "attendees"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "days", default: 7
    t.string "meeting_type"
    t.string "number", null: false
    t.string "resource_uri", null: false
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.string "venue_name"
    t.index ["date"], name: "index_meetings_on_date"
    t.index ["meeting_type"], name: "index_meetings_on_meeting_type"
    t.index ["number"], name: "index_meetings_on_number", unique: true
    t.index ["resource_uri"], name: "index_meetings_on_resource_uri", unique: true
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "application_id", null: false
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.integer "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.integer "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "session_presentations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.integer "order"
    t.string "resource_uri", null: false
    t.string "rev"
    t.integer "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_session_presentations_on_document_id"
    t.index ["resource_uri"], name: "index_session_presentations_on_resource_uri", unique: true
    t.index ["session_id", "document_id"], name: "index_session_presentations_on_session_id_and_document_id", unique: true
    t.index ["session_id"], name: "index_session_presentations_on_session_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "attendees"
    t.datetime "created_at", null: false
    t.integer "datatracker_id"
    t.integer "group_id"
    t.integer "meeting_id", null: false
    t.string "name"
    t.boolean "on_agenda"
    t.string "purpose"
    t.string "remote_instructions"
    t.string "requested_duration"
    t.string "resource_uri", null: false
    t.datetime "updated_at", null: false
    t.index ["datatracker_id"], name: "index_sessions_on_datatracker_id", unique: true
    t.index ["group_id"], name: "index_sessions_on_group_id"
    t.index ["meeting_id"], name: "index_sessions_on_meeting_id"
    t.index ["resource_uri"], name: "index_sessions_on_resource_uri", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "general", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "document_material_uploaded_bies", "document_materials"
  add_foreign_key "document_material_uploaded_bies", "users"
  add_foreign_key "document_materials", "documents"
  add_foreign_key "documents", "groups"
  add_foreign_key "github_authentications", "users"
  add_foreign_key "groups", "groups", column: "parent_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "session_presentations", "documents"
  add_foreign_key "session_presentations", "sessions"
  add_foreign_key "sessions", "groups"
  add_foreign_key "sessions", "meetings"
end
