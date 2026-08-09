class CreateKeepInTouchSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :keep_in_touch_settings do |t|
      t.references :friend, null: false, foreign_key: true, index: { unique: true }
      t.string :cadence, null: false
      t.date :enabled_on
      t.date :snoozed_until
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :keep_in_touch_settings,
      "cadence IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly')",
      name: "keep_in_touch_settings_cadence_is_supported"
    add_check_constraint :keep_in_touch_settings,
      "enabled_on IS NOT NULL OR snoozed_until IS NULL",
      name: "keep_in_touch_settings_disabled_cannot_be_snoozed"
  end
end
