class AddReminderDeliveryClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :reminder_deliveries, :attempts, :integer, null: false, default: 0
    add_column :reminder_deliveries, :claimed_at, :datetime
    add_column :reminder_deliveries, :claim_token, :string

    add_check_constraint :reminder_deliveries,
      "attempts >= 0",
      name: "reminder_deliveries_attempts_are_nonnegative"
    add_check_constraint :reminder_deliveries,
      "(claimed_at IS NULL AND claim_token IS NULL) OR (claimed_at IS NOT NULL AND claim_token IS NOT NULL)",
      name: "reminder_deliveries_claim_is_complete"
  end
end
