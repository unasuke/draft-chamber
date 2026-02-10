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

ActiveRecord::Schema[8.1].define(version: 2026_02_10_105339) do
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

  add_foreign_key "documents", "groups"
  add_foreign_key "groups", "groups", column: "parent_id"
  add_foreign_key "session_presentations", "documents"
  add_foreign_key "session_presentations", "sessions"
  add_foreign_key "sessions", "groups"
  add_foreign_key "sessions", "meetings"
end
