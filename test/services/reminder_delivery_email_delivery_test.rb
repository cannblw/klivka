require "test_helper"

class ReminderDeliveryEmailDeliveryTest < ActiveSupport::TestCase
  test "selects birthday and significant-date mailers from their entry source" do
    birthday_delivery = birthday_delivery()
    date_entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7), content: { "label" => "Moving day" })
    date_reminder = date_entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    date_delivery = create_delivery(date_reminder, reminder_on: Date.new(2026, 9, 6), occurrence_on: Date.new(2026, 9, 7))
    transport = RecordingTransport.new

    ReminderDeliveryEmailDelivery.call(delivery_id: birthday_delivery.id, at: delivery_time, transport:)
    ReminderDeliveryEmailDelivery.call(delivery_id: date_delivery.id, at: delivery_time, transport:)

    assert_equal "Ada Lovelace's birthday is coming up", transport.messages.fetch(0).subject
    assert_equal "Ada Lovelace: Moving day is coming up", transport.messages.fetch(1).subject
  end

  test "records a failed individual date attempt and allows a later retry" do
    delivery = birthday_delivery

    assert_raises MailTransports::DeliveryError do
      ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time, transport: FailingTransport.new)
    end

    assert_equal ReminderDelivery::FAILED_STATUS, delivery.reload.status
    assert_equal 1, delivery.attempts
    assert_equal delivery_time, delivery.failed_at
    assert_nil delivery.claimed_at

    ReminderDeliveryEmailDelivery.call(
      delivery_id: delivery.id, at: delivery_time + 1.minute, transport: RecordingTransport.new
    )

    assert_equal ReminderDelivery::DELIVERED_STATUS, delivery.reload.status
    assert_equal 2, delivery.attempts
  end

  test "does not deliver person email work through the individual path" do
    person = people(:ada)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(person, reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8))
    transport = RecordingTransport.new

    assert_nil ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time, transport:)

    assert_equal ReminderDelivery::PENDING_STATUS, delivery.reload.status
    assert_empty transport.messages
  end

  test "marks an exhausted abandoned individual claim as failed" do
    delivery = birthday_delivery
    delivery.update!(
      attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
      claimed_at: delivery_time - Rails.application.config.x.reminder_delivery_claim_timeout - 1.minute,
      claim_token: "abandoned-claim"
    )

    ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time)

    assert_equal ReminderDelivery::FAILED_STATUS, delivery.reload.status
    assert_equal delivery_time, delivery.failed_at
    assert_nil delivery.claimed_at
    assert_nil delivery.claim_token
  end

  private

  def birthday_delivery
    create_delivery(
      entries(:ada_birthday),
      reminder_on: Date.new(2026, 11, 10),
      occurrence_on: Date.new(2026, 12, 10)
    )
  end

  def create_delivery(source, reminder_on:, occurrence_on:)
    ReminderDelivery.create!(
      user: users(:one), source:, channel: "email", reminder_on:, occurrence_on:
    )
  end

  def delivery_time
    Time.utc(2026, 11, 10, 12)
  end

  class RecordingTransport
    attr_reader :messages

    def initialize
      @messages = []
    end

    def deliver(message:, delivery_id:)
      @messages << message
      { identifier: delivery_id }
    end
  end

  class FailingTransport
    def deliver(message:, delivery_id:)
      raise MailTransports::DeliveryError, "provider unavailable"
    end
  end
end
