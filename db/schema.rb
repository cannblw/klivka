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

ActiveRecord::Schema[8.1].define(version: 2026_08_02_100000) do
  create_table "entries", force: :cascade do |t|
    t.json "content"
    t.datetime "created_at", null: false
    t.date "entry_date"
    t.integer "friend_id", null: false
    t.integer "position", default: 0, null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_date"], name: "index_entries_on_entry_date"
    t.index ["friend_id", "position"], name: "index_entries_on_friend_id_and_position"
    t.index ["friend_id"], name: "index_entries_on_friend_id"
    t.index ["friend_id"], name: "index_entries_on_friend_id_for_birthday", unique: true, where: "type = 'Entry::Birthday'"
    t.index ["friend_id"], name: "index_entries_on_friend_id_for_first_met", unique: true, where: "type = 'Entry::FirstMet'"
    t.check_constraint "(type IN ('Entry::Date', 'Entry::Birthday', 'Entry::FirstMet') AND entry_date IS NOT NULL) OR (type NOT IN ('Entry::Date', 'Entry::Birthday', 'Entry::FirstMet') AND entry_date IS NULL)", name: "entries_date_types_require_entry_date"
    t.check_constraint "position >= 0", name: "entries_position_non_negative"
  end

  create_table "friends", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_friends_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale"
    t.string "password_digest", null: false
    t.string "theme"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "entries", "friends"
  add_foreign_key "friends", "users"
  add_foreign_key "sessions", "users"
end
