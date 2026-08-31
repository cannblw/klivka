class AddFirstContactReminderDates < ActiveRecord::Migration[8.1]
  CADENCE_INTERVALS = {
    "daily" => { days: 1 },
    "weekly" => { weeks: 1 },
    "biweekly" => { weeks: 2 },
    "monthly" => { months: 1 },
    "quarterly" => { months: 3 },
    "yearly" => { years: 1 }
  }.freeze

  class UserRecord < ActiveRecord::Base
    self.table_name = "users"
  end

  class KeepInTouchSettingRecord < ActiveRecord::Base
    self.table_name = "keep_in_touch_settings"
  end

  def up
    add_column :users, :contact_reminder_first_reminder_on, :date
    add_column :keep_in_touch_settings, :first_reminder_on, :date

    UserRecord.reset_column_information
    UserRecord.where.not(contact_reminders_enabled_on: nil).find_each do |user|
      user.update_columns(
        contact_reminder_first_reminder_on: first_reminder_on(
          enabled_on: user.contact_reminders_enabled_on,
          cadence: user.contact_reminder_cadence
        )
      )
    end

    KeepInTouchSettingRecord.reset_column_information
    KeepInTouchSettingRecord.where.not(enabled_on: nil).find_each do |setting|
      setting.update_columns(
        first_reminder_on: first_reminder_on(enabled_on: setting.enabled_on, cadence: setting.cadence)
      )
    end

    add_check_constraint :users,
      "(contact_reminders_enabled_on IS NULL AND contact_reminder_first_reminder_on IS NULL) OR " \
        "(contact_reminders_enabled_on IS NOT NULL AND contact_reminder_first_reminder_on IS NOT NULL " \
        "AND contact_reminder_first_reminder_on > contact_reminders_enabled_on)",
      name: "users_contact_reminder_dates_are_consistent"
    add_check_constraint :keep_in_touch_settings,
      "(enabled_on IS NULL AND first_reminder_on IS NULL) OR " \
        "(enabled_on IS NOT NULL AND first_reminder_on IS NOT NULL AND first_reminder_on > enabled_on)",
      name: "keep_in_touch_settings_reminder_dates_are_consistent"
  end

  def down
    remove_check_constraint :keep_in_touch_settings,
      name: "keep_in_touch_settings_reminder_dates_are_consistent"
    remove_check_constraint :users, name: "users_contact_reminder_dates_are_consistent"
    remove_column :keep_in_touch_settings, :first_reminder_on
    remove_column :users, :contact_reminder_first_reminder_on
  end

  private

  def first_reminder_on(enabled_on:, cadence:)
    enabled_on.advance(**CADENCE_INTERVALS.fetch(cadence))
  end
end
