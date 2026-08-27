require "test_helper"

# == Schema Information
#
# Table name: reminder_deliveries
#
#  id            :integer          not null, primary key
#  attempts      :integer          default(0), not null
#  canceled_at   :datetime
#  channel       :string           not null
#  claim_token   :string
#  claimed_at    :datetime
#  delivered_at  :datetime
#  failed_at     :datetime
#  occurrence_on :date             not null
#  reminder_on   :date             not null
#  source_type   :string           not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  source_id     :integer          not null
#  user_id       :integer          not null
#
# Indexes
#
#  idx_on_status_channel_reminder_on_f9dde1d6e2          (status,channel,reminder_on)
#  index_reminder_deliveries_on_source_date_and_channel  (source_type,source_id,reminder_on,channel) UNIQUE
#  index_reminder_deliveries_on_user_id                  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class ReminderDeliveryTest < ActiveSupport::TestCase
  setup do
    @setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
  end

  test "records separate in-app and email work for one reminder occurrence" do
    attributes = {
      user: users(:one), source: @setting,
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    }

    in_app = ReminderDelivery.create!(**attributes, channel: "in_app")
    email = ReminderDelivery.create!(**attributes, channel: "email")

    assert_equal "pending", in_app.status
    assert_equal "pending", email.status
  end

  test "allows different reminder dates for a recurring source" do
    ReminderDelivery.create!(
      user: users(:one), source: @setting, channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    )

    assert_difference "ReminderDelivery.count", 1 do
      ReminderDelivery.create!(
        user: users(:one), source: @setting, channel: "email",
        reminder_on: Date.new(2026, 8, 15), occurrence_on: Date.new(2026, 8, 15)
      )
    end
  end

  test "rejects duplicate work for one source date and channel" do
    attributes = {
      user: users(:one), source: @setting, channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    }
    ReminderDelivery.create!(attributes)

    duplicate = ReminderDelivery.new(attributes)

    assert_not_predicate duplicate, :valid?
    assert duplicate.errors.of_kind?(:channel, :taken)
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "requires supported sources channels statuses and dates" do
    delivery = ReminderDelivery.new(user: users(:one), source: @setting, channel: "push", status: "queued")

    assert_not_predicate delivery, :valid?
    assert delivery.errors.of_kind?(:channel, :inclusion)
    assert delivery.errors.of_kind?(:status, :inclusion)
    assert delivery.errors.of_kind?(:reminder_on, :blank)
    assert delivery.errors.of_kind?(:occurrence_on, :blank)
  end

  test "the database rejects unsupported scheduling values" do
    delivery = ReminderDelivery.create!(
      user: users(:one), source: @setting, channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    )

    assert_raises(ActiveRecord::StatementInvalid) { delivery.update_column(:channel, "push") }
    assert_raises(ActiveRecord::StatementInvalid) { delivery.update_column(:status, "queued") }
    assert_raises(ActiveRecord::StatementInvalid) { delivery.update_column(:source_type, "Person") }
  end

  test "requires complete claim metadata at the model and database boundaries" do
    delivery = ReminderDelivery.create!(
      user: users(:one), source: @setting, channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    )

    delivery.claimed_at = Time.utc(2026, 8, 8, 12)
    assert_not_predicate delivery, :valid?
    assert delivery.errors.of_kind?(:claim_token, :blank)

    delivery.claimed_at = nil
    delivery.claim_token = "claim-token"
    assert_not_predicate delivery, :valid?
    assert delivery.errors.of_kind?(:claimed_at, :blank)

    assert_raises(ActiveRecord::StatementInvalid) do
      delivery.update_columns(claimed_at: Time.utc(2026, 8, 8, 12), claim_token: nil)
    end
    assert_raises(ActiveRecord::StatementInvalid) { delivery.update_column(:attempts, -1) }
  end

  test "requires the source and ledger record to belong to the same user" do
    delivery = ReminderDelivery.new(
      user: users(:two), source: @setting, channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    )

    assert_not_predicate delivery, :valid?
    assert delivery.errors.of_kind?(:source, :invalid)
  end

  test "supports birthdays but rejects other entry types as delivery sources" do
    birthday_delivery = ReminderDelivery.new(
      user: users(:one), source: entries(:ada_birthday), channel: "email",
      reminder_on: Date.new(2026, 11, 10), occurrence_on: Date.new(2026, 12, 10)
    )
    date_entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 12, 10))
    date_delivery = ReminderDelivery.new(
      user: users(:one), source: date_entry, channel: "email",
      reminder_on: Date.new(2026, 11, 10), occurrence_on: Date.new(2026, 12, 10)
    )

    assert_predicate birthday_delivery, :valid?
    assert_not_predicate date_delivery, :valid?
    assert date_delivery.errors.of_kind?(:source, :invalid)
  end

  test "keeps the audit record when its reminder source is deleted" do
    delivery = ReminderDelivery.create!(
      user: users(:one), source: @setting, channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    )

    assert_no_difference "ReminderDelivery.count" do
      @setting.destroy!
    end

    assert_nil delivery.reload.source
  end

  test "deleting the owning account deletes its delivery history" do
    user = User.create!(email_address: "ledger-owner@example.com", password: "password", time_zone: "UTC")
    person = user.people.create!(name: "Ledger source")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    ReminderDelivery.create!(
      user:, source: setting, channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8)
    )

    assert_difference "ReminderDelivery.count", -1 do
      user.destroy!
    end
  end
end
