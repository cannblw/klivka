class AddGlobalContactReminders < ActiveRecord::Migration[8.1]
  class PreviousKeepInTouchSetting < ActiveRecord::Base
    self.table_name = "keep_in_touch_settings"
  end

  class PersonRecord < ActiveRecord::Base
    self.table_name = "people"
  end

  class ReminderDeliveryRecord < ActiveRecord::Base
    self.table_name = "reminder_deliveries"
  end

  def up
    add_column :users, :contact_reminder_cadence, :string, null: false, default: "monthly"
    add_column :users, :contact_reminders_enabled_on, :date
    add_check_constraint :users,
      "contact_reminder_cadence IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly')",
      name: "users_contact_reminder_cadence_is_supported"

    add_column :people, :contact_reminder_snoozed_until, :date

    # SQLite can retain a degraded single-column index after table-renaming migrations; restore the tenant-scoped shape.
    remove_index :people, name: :index_people_on_archived_at if index_exists?(:people, :archived_at, name: :index_people_on_archived_at)
    unless index_exists?(:people, [ :user_id, :archived_at ], name: :index_people_on_user_id_and_archived_at)
      add_index :people, [ :user_id, :archived_at ]
    end

    PreviousKeepInTouchSetting.where.not(snoozed_until: nil).find_each do |setting|
      PersonRecord.where(id: setting.person_id).update_all(contact_reminder_snoozed_until: setting.snoozed_until)
    end

    remove_check_constraint :keep_in_touch_settings, name: "keep_in_touch_settings_disabled_cannot_be_snoozed"
    remove_column :keep_in_touch_settings, :snoozed_until, :date
    remove_column :keep_in_touch_settings, :lock_version, :integer

    remove_check_constraint :reminder_deliveries, name: "reminder_deliveries_source_type_is_supported"

    PreviousKeepInTouchSetting.find_each do |setting|
      ReminderDeliveryRecord.where(source_type: "KeepInTouchSetting", source_id: setting.id)
        .update_all(source_type: "Person", source_id: setting.person_id)
    end

    # A deleted polymorphic source leaves no reliable person identity to migrate.
    ReminderDeliveryRecord.where(source_type: "KeepInTouchSetting").delete_all

    add_check_constraint :reminder_deliveries,
      "source_type IN ('Person', 'EntryReminder', 'Entry')",
      name: "reminder_deliveries_source_type_is_supported"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "person-backed reminder deliveries cannot be mapped safely back to optional keep-in-touch settings"
  end
end
