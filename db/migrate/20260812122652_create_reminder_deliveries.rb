class CreateReminderDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :reminder_deliveries do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :source_type, null: false
      t.integer :source_id, null: false
      t.string :channel, null: false
      t.string :status, null: false, default: "pending"
      t.date :reminder_on, null: false
      t.date :occurrence_on, null: false
      t.datetime :delivered_at
      t.datetime :failed_at
      t.datetime :cancelled_at
      t.timestamps
    end

    # Polymorphic source ids intentionally have no foreign key so deleting a reminder can retain its audit record.
    add_index :reminder_deliveries,
      %i[source_type source_id reminder_on channel],
      unique: true,
      name: "index_reminder_deliveries_on_source_date_and_channel"
    add_index :reminder_deliveries, %i[status channel reminder_on]

    # Model validations do not protect concurrent workers or bulk writes, so constrain the scheduling vocabulary in both adapters.
    add_check_constraint :reminder_deliveries,
      "source_type IN ('KeepInTouchSetting', 'EntryReminder')",
      name: "reminder_deliveries_source_type_is_supported"
    add_check_constraint :reminder_deliveries,
      "channel IN ('in_app', 'email')",
      name: "reminder_deliveries_channel_is_supported"
    add_check_constraint :reminder_deliveries,
      "status IN ('pending', 'delivered', 'failed', 'cancelled')",
      name: "reminder_deliveries_status_is_supported"
  end
end
