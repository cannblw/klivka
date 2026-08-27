require "test_helper"

class ReminderDeliveryEmailDeliveryTest < ActiveSupport::TestCase
  test "delivers a keep-in-touch email and records the provider result" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(setting)
    transport = RecordingTransport.new

    result = ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time, transport:)

    assert_equal({ identifier: "provider-id" }, result)

    delivery.reload
    assert_equal "delivered", delivery.status
    assert_equal 1, delivery.attempts
    assert_equal delivery_time, delivery.delivered_at
    assert_nil delivery.claimed_at
    assert_equal "reminder-delivery/#{delivery.id}", transport.delivery_id
    assert_equal "A reminder to keep in touch with Ada Lovelace", transport.message.subject
  end

  test "selects birthday and significant-date mailers from their entry source" do
    birthday_delivery = create_delivery(
      entries(:ada_birthday),
      reminder_on: Date.new(2026, 11, 10),
      occurrence_on: Date.new(2026, 12, 10)
    )
    date_entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7), content: { "label" => "Moving day" })
    date_reminder = date_entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    date_delivery = create_delivery(date_reminder, reminder_on: Date.new(2026, 9, 6), occurrence_on: Date.new(2026, 9, 7))
    transport = RecordingTransport.new

    ReminderDeliveryEmailDelivery.call(delivery_id: birthday_delivery.id, at: delivery_time, transport:)
    ReminderDeliveryEmailDelivery.call(delivery_id: date_delivery.id, at: delivery_time, transport:)

    assert_equal "Ada Lovelace's birthday is coming up", transport.messages.fetch(0).subject
    assert_equal "Ada Lovelace: Moving day is coming up", transport.messages.fetch(1).subject
  end

  test "records a failed attempt and allows a later retry" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(setting)
    transport = FailingTransport.new

    assert_raises MailTransports::DeliveryError do
      ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time, transport:)
    end

    delivery.reload
    assert_equal "failed", delivery.status
    assert_equal 1, delivery.attempts
    assert_equal delivery_time, delivery.failed_at
    assert_nil delivery.claimed_at

    delivery.update!(failed_at: delivery_time - 1.minute)
    successful_transport = RecordingTransport.new
    ReminderDeliveryEmailDelivery.call(
      delivery_id: delivery.id, at: delivery_time + 1.minute, transport: successful_transport
    )

    assert_equal "delivered", delivery.reload.status
    assert_equal 2, delivery.attempts
  end

  test "cancels a claimed delivery when its reminder is no longer current" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(setting)
    setting.disable!
    transport = RecordingTransport.new

    ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time, transport:)

    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
    assert_empty transport.messages
  end

  test "does not overwrite a newer outcome after its claim expires" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(setting)
    transport = ReplacingTransport.new(delivery:, replaced_at: delivery_time + 1.minute)

    ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time, transport:)

    delivery.reload
    assert_equal "delivered", delivery.status
    assert_equal delivery_time + 1.minute, delivery.delivered_at
    assert_nil delivery.claim_token
  end

  test "marks an exhausted abandoned claim as failed" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(setting)
    delivery.update!(
      attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
      claimed_at: delivery_time - Rails.application.config.x.reminder_delivery_claim_timeout - 1.minute,
      claim_token: "abandoned-claim"
    )

    ReminderDeliveryEmailDelivery.call(delivery_id: delivery.id, at: delivery_time)

    delivery.reload
    assert_equal "failed", delivery.status
    assert_equal delivery_time, delivery.failed_at
    assert_nil delivery.claimed_at
    assert_nil delivery.claim_token
  end

  private

  def create_delivery(source, reminder_on: Date.new(2026, 8, 8), occurrence_on: reminder_on)
    ReminderDelivery.create!(
      user: users(:one), source:, channel: "email", reminder_on:, occurrence_on:
    )
  end

  def delivery_time
    Time.utc(2026, 8, 8, 12)
  end

  class RecordingTransport
    attr_reader :message, :messages, :delivery_id

    def initialize
      @messages = []
    end

    def deliver(message:, delivery_id:)
      @message = message
      @messages << message
      @delivery_id = delivery_id
      { identifier: "provider-id" }
    end
  end

  class FailingTransport
    def deliver(message:, delivery_id:)
      raise MailTransports::DeliveryError, "provider unavailable"
    end
  end

  class ReplacingTransport
    def initialize(delivery:, replaced_at:)
      @delivery = delivery
      @replaced_at = replaced_at
    end

    def deliver(message:, delivery_id:)
      @delivery.update_columns(
        status: "delivered",
        delivered_at: @replaced_at,
        claimed_at: nil,
        claim_token: nil,
        updated_at: @replaced_at
      )
      { identifier: "newer-delivery" }
    end
  end
end
