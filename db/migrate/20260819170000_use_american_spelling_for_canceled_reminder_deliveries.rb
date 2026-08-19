class UseAmericanSpellingForCanceledReminderDeliveries < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :reminder_deliveries, name: "reminder_deliveries_status_is_supported"
    rename_column :reminder_deliveries, :cancelled_at, :canceled_at
    add_status_constraint("canceled")
  end

  def down
    remove_check_constraint :reminder_deliveries, name: "reminder_deliveries_status_is_supported"
    rename_column :reminder_deliveries, :canceled_at, :cancelled_at
    add_status_constraint("cancelled")
  end

  private

  def add_status_constraint(canceled_status)
    add_check_constraint :reminder_deliveries,
      "status IN ('pending', 'delivered', 'failed', '#{canceled_status}')",
      name: "reminder_deliveries_status_is_supported"
  end
end
