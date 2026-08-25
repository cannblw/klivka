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

ActiveRecord::Schema[8.1].define(version: 2026_08_25_120000) do
  create_table "demo_states", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "last_activity_at", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_demo_states_on_key", unique: true
    t.check_constraint "key = 'shared'", name: "demo_states_key_is_shared"
    t.check_constraint "last_activity_at >= started_at", name: "demo_states_activity_is_within_current_cycle"
  end

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

  create_table "entry_reminders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "entry_id", null: false
    t.string "lead_unit", null: false
    t.integer "lead_value", null: false
    t.string "recurrence", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_entry_reminders_on_entry_id", unique: true
    t.check_constraint "lead_value BETWEEN 0 AND 2147483647 AND lead_unit IN ('days', 'months', 'years')", name: "entry_reminders_lead_is_supported"
    t.check_constraint "recurrence IN ('one_time', 'yearly')", name: "entry_reminders_recurrence_is_supported"
  end

  create_table "friends", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "slug"], name: "index_friends_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_friends_on_user_id"
  end

  create_table "interactions", force: :cascade do |t|
    t.string "contact_method"
    t.datetime "created_at", null: false
    t.integer "friend_id", null: false
    t.text "note"
    t.date "occurred_on", null: false
    t.datetime "updated_at", null: false
    t.index ["friend_id", "occurred_on"], name: "index_interactions_on_friend_id_and_occurred_on"
    t.index ["friend_id"], name: "index_interactions_on_friend_id"
    t.check_constraint "contact_method IS NULL OR contact_method IN ('call', 'message', 'video', 'in_person', 'other')", name: "interactions_contact_method_is_supported"
  end

  create_table "keep_in_touch_settings", force: :cascade do |t|
    t.string "cadence", null: false
    t.datetime "created_at", null: false
    t.date "enabled_on"
    t.integer "friend_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.date "snoozed_until"
    t.datetime "updated_at", null: false
    t.index ["friend_id"], name: "index_keep_in_touch_settings_on_friend_id", unique: true
    t.check_constraint "cadence IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly')", name: "keep_in_touch_settings_cadence_is_supported"
    t.check_constraint "enabled_on IS NOT NULL OR snoozed_until IS NULL", name: "keep_in_touch_settings_disabled_cannot_be_snoozed"
  end

  create_table "reminder_deliveries", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "canceled_at"
    t.string "channel", null: false
    t.string "claim_token"
    t.datetime "claimed_at"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.datetime "failed_at"
    t.date "occurrence_on", null: false
    t.date "reminder_on", null: false
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["source_type", "source_id", "reminder_on", "channel"], name: "index_reminder_deliveries_on_source_date_and_channel", unique: true
    t.index ["status", "channel", "reminder_on"], name: "idx_on_status_channel_reminder_on_f9dde1d6e2"
    t.index ["user_id"], name: "index_reminder_deliveries_on_user_id"
    t.check_constraint "(claimed_at IS NULL AND claim_token IS NULL) OR (claimed_at IS NOT NULL AND claim_token IS NOT NULL)", name: "reminder_deliveries_claim_is_complete"
    t.check_constraint "attempts >= 0", name: "reminder_deliveries_attempts_are_nonnegative"
    t.check_constraint "channel IN ('in_app', 'email')", name: "reminder_deliveries_channel_is_supported"
    t.check_constraint "source_type IN ('KeepInTouchSetting', 'EntryReminder')", name: "reminder_deliveries_source_type_is_supported"
    t.check_constraint "status IN ('pending', 'delivered', 'failed', 'canceled')", name: "reminder_deliveries_status_is_supported"
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
    t.string "birthday_reminder_lead_unit", default: "months", null: false
    t.integer "birthday_reminder_lead_value", default: 1, null: false
    t.boolean "birthday_reminders_enabled", default: true, null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "default_reminder_lead_unit", default: "months", null: false
    t.integer "default_reminder_lead_value", default: 1, null: false
    t.string "email_address", null: false
    t.string "locale"
    t.string "password_digest", null: false
    t.boolean "reminder_email_enabled", default: true, null: false
    t.boolean "reminder_in_app_enabled", default: true, null: false
    t.date "reminders_scanned_through_on"
    t.string "theme"
    t.string "time_zone", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["reminders_scanned_through_on"], name: "index_users_on_reminders_scanned_through_on"
    t.check_constraint "birthday_reminder_lead_value BETWEEN 0 AND 2147483647 AND birthday_reminder_lead_unit IN ('days', 'months', 'years')", name: "users_birthday_reminder_lead_is_supported"
    t.check_constraint "birthday_reminders_enabled IN (TRUE, FALSE)", name: "users_birthday_reminders_enabled_is_boolean"
    t.check_constraint "default_reminder_lead_value BETWEEN 0 AND 2147483647 AND default_reminder_lead_unit IN ('days', 'months', 'years')", name: "users_default_reminder_lead_is_supported"
    t.check_constraint "reminder_email_enabled IN (TRUE, FALSE)", name: "users_reminder_email_enabled_is_boolean"
    t.check_constraint "reminder_in_app_enabled IN (TRUE, FALSE)", name: "users_reminder_in_app_enabled_is_boolean"
  end

  create_table "vcard_imports", force: :cascade do |t|
    t.json "candidates", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "rejected_count", default: 0, null: false
    t.json "selected_candidate_ids", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["expires_at"], name: "index_vcard_imports_on_expires_at"
    t.index ["user_id"], name: "index_vcard_imports_on_user_id"
    t.check_constraint "rejected_count >= 0", name: "vcard_imports_rejected_count_is_nonnegative"
  end

  add_foreign_key "entries", "friends"
  add_foreign_key "entry_reminders", "entries", on_delete: :cascade
  add_foreign_key "friends", "users"
  add_foreign_key "interactions", "friends"
  add_foreign_key "keep_in_touch_settings", "friends"
  add_foreign_key "reminder_deliveries", "users", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "vcard_imports", "users", on_delete: :cascade
end
