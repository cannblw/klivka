class AddReminderScanCheckpointToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :reminders_scanned_through_on, :date
    add_index :users, :reminders_scanned_through_on
  end
end
