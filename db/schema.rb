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

ActiveRecord::Schema[7.1].define(version: 2025_02_05_084836) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "collaborators", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "note_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_collaborators_on_note_id"
    t.index ["user_id"], name: "index_collaborators_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "color"
    t.boolean "is_deleted"
    t.boolean "is_archived"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notes_users", id: false, force: :cascade do |t|
    t.bigint "note_id", null: false
    t.bigint "user_id", null: false
    t.index ["note_id", "user_id"], name: "index_notes_users_on_note_id_and_user_id"
    t.index ["user_id", "note_id"], name: "index_notes_users_on_user_id_and_note_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "mobile_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "otp"
    t.datetime "otp_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["mobile_number"], name: "index_users_on_mobile_number", unique: true
  end

  add_foreign_key "collaborators", "notes"
  add_foreign_key "collaborators", "users"
  add_foreign_key "notes", "users"
end
