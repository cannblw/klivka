class CreateContactReminderDigests < ActiveRecord::Migration[8.1]
  DIGEST_STATUSES = %w[pending delivered failed canceled].freeze

  def change
    create_table :contact_reminder_digests do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.date :delivery_on, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.datetime :claimed_at
      t.string :claim_token
      t.datetime :delivered_at
      t.datetime :failed_at
      t.datetime :canceled_at
      t.timestamps
    end

    add_index :contact_reminder_digests, %i[user_id delivery_on], unique: true
    add_index :contact_reminder_digests, %i[status delivery_on]
    add_check_constraint :contact_reminder_digests,
      "status IN (#{DIGEST_STATUSES.map { |status| connection.quote(status) }.join(", ")})",
      name: "contact_reminder_digests_status_is_supported"
    add_check_constraint :contact_reminder_digests,
      "attempts >= 0",
      name: "contact_reminder_digests_attempts_are_nonnegative"
    add_check_constraint :contact_reminder_digests,
      "(claimed_at IS NULL AND claim_token IS NULL) OR (claimed_at IS NOT NULL AND claim_token IS NOT NULL)",
      name: "contact_reminder_digests_claim_is_complete"

    add_reference :reminder_deliveries, :contact_reminder_digest,
      foreign_key: true,
      index: true
  end
end
