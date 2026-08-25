class AddBirthdayReminderPreferences < ActiveRecord::Migration[8.1]
  class EntryRecord < ActiveRecord::Base
    self.table_name = "entries"
  end

  class EntryReminderRecord < ActiveRecord::Base
    self.table_name = "entry_reminders"
  end

  class ReminderDeliveryRecord < ActiveRecord::Base
    self.table_name = "reminder_deliveries"
  end

  class UserRecord < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :users, :birthday_reminders_enabled, :boolean, null: false, default: true
    add_column :users, :birthday_reminder_lead_value, :integer
    add_column :users, :birthday_reminder_lead_unit, :string

    UserRecord.reset_column_information
    UserRecord.find_each do |user|
      user.update_columns(
        birthday_reminder_lead_value: user.default_reminder_lead_value,
        birthday_reminder_lead_unit: user.default_reminder_lead_unit
      )
    end

    change_column_null :users, :birthday_reminder_lead_value, false
    change_column_null :users, :birthday_reminder_lead_unit, false
    change_column_default :users, :birthday_reminder_lead_value, from: nil, to: 1
    change_column_default :users, :birthday_reminder_lead_unit, from: nil, to: "months"

    add_check_constraint :users,
      "birthday_reminders_enabled IN (TRUE, FALSE)",
      name: "users_birthday_reminders_enabled_is_boolean"
    add_check_constraint :users,
      <<~SQL.squish,
        birthday_reminder_lead_value BETWEEN 0 AND #{FriendCrm::MAX_INT32} AND
        birthday_reminder_lead_unit IN ('days', 'months', 'years')
      SQL
      name: "users_birthday_reminder_lead_is_supported"

    remove_check_constraint :reminder_deliveries, name: "reminder_deliveries_source_type_is_supported"
    # Polymorphic associations store the STI base class, so birthday delivery sources are represented as Entry.
    add_check_constraint :reminder_deliveries,
      "source_type IN ('KeepInTouchSetting', 'EntryReminder', 'Entry')",
      name: "reminder_deliveries_source_type_is_supported"

    birthday_reminders = EntryReminderRecord.where(
      entry_id: EntryRecord.where(type: "Entry::Birthday").select(:id)
    )
    ReminderDeliveryRecord.where(source_type: "EntryReminder", source_id: birthday_reminders.select(:id)).delete_all
    birthday_reminders.delete_all
  end

  def down
    remove_check_constraint :reminder_deliveries, name: "reminder_deliveries_source_type_is_supported"
    add_check_constraint :reminder_deliveries,
      "source_type IN ('KeepInTouchSetting', 'EntryReminder')",
      name: "reminder_deliveries_source_type_is_supported"
    remove_check_constraint :users, name: "users_birthday_reminder_lead_is_supported"
    remove_check_constraint :users, name: "users_birthday_reminders_enabled_is_boolean"
    remove_column :users, :birthday_reminder_lead_unit
    remove_column :users, :birthday_reminder_lead_value
    remove_column :users, :birthday_reminders_enabled
  end
end
