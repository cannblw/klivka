class AddReminderPreferences < ActiveRecord::Migration[8.1]
  def change
    # PostgreSQL integers are signed 32-bit values; this explicit limit keeps SQLite from accepting data PostgreSQL cannot.
    reminder_lead_value_limit = 2_147_483_647

    add_column :users, :reminder_in_app_enabled, :boolean, null: false, default: true
    add_column :users, :reminder_email_enabled, :boolean, null: false, default: true
    add_column :users, :default_reminder_lead_value, :integer, null: false, default: 1
    add_column :users, :default_reminder_lead_unit, :string, null: false, default: "months"

    create_table :entry_reminders do |t|
      t.references :entry, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.integer :lead_value, null: false
      t.string :lead_unit, null: false
      t.timestamps
    end

    # SQLite accepts arbitrary integers in boolean columns, so constrain its 1/0 representation while PostgreSQL uses native TRUE/FALSE.
    add_check_constraint :users,
      "reminder_in_app_enabled IN (TRUE, FALSE)",
      name: "users_reminder_in_app_enabled_is_boolean"
    add_check_constraint :users,
      "reminder_email_enabled IN (TRUE, FALSE)",
      name: "users_reminder_email_enabled_is_boolean"

    # Model validations do not protect bulk writes, so persist only units and values the reminder calculation can interpret.
    add_check_constraint :users,
      <<~SQL.squish,
        default_reminder_lead_value BETWEEN 0 AND #{reminder_lead_value_limit} AND
        default_reminder_lead_unit IN ('days', 'months', 'years')
      SQL
      name: "users_default_reminder_lead_is_supported"

    add_check_constraint :entry_reminders,
      <<~SQL.squish,
        lead_value BETWEEN 0 AND #{reminder_lead_value_limit} AND
        lead_unit IN ('days', 'months', 'years')
      SQL
      name: "entry_reminders_lead_is_supported"
  end
end
