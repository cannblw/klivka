require "test_helper"

class ContactReminderDigestEmailDeliveryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @delivery_time = Time.utc(2026, 8, 8, 12)
    @delivery_on = @user.local_date(at: @delivery_time)
  end

  test "delivers one email and completes every current member" do
    first = create_due_delivery(people(:ada))
    second = create_due_delivery(people(:grace))
    digest = create_digest(first, second)
    transport = RecordingTransport.new

    result = ContactReminderDigestEmailDelivery.call(
      digest_id: digest.id, at: @delivery_time, transport:
    )

    assert_equal({ identifier: "provider-id" }, result)
    assert_equal "contact-reminder-digest/#{digest.id}", transport.delivery_id
    assert_equal ContactReminderDigest::DELIVERED_STATUS, digest.reload.status
    assert_equal @delivery_time, digest.delivered_at
    assert_equal 1, digest.attempts
    assert_nil digest.claimed_at
    assert_equal [ ReminderDelivery::DELIVERED_STATUS ],
      digest.reminder_deliveries.reload.distinct.pluck(:status)
    assert_includes transport.message.text_part.body.to_s, people(:ada).name
    assert_includes transport.message.text_part.body.to_s, people(:grace).name
  end

  test "uses the digest path when only one person is due" do
    delivery = create_due_delivery(people(:ada))
    digest = create_digest(delivery)
    transport = RecordingTransport.new

    ContactReminderDigestEmailDelivery.call(digest_id: digest.id, at: @delivery_time, transport:)

    assert_equal "contact-reminder-digest/#{digest.id}", transport.delivery_id
    assert_includes transport.message.text_part.body.to_s, people(:ada).name
    assert_includes transport.message.text_part.body.to_s, "http://localhost:3000/reminders"
  end

  test "limits the email preview through application configuration" do
    first = create_due_delivery(people(:ada))
    second = create_due_delivery(people(:grace))
    digest = create_digest(first, second)
    transport = RecordingTransport.new
    configuration = Rails.application.config.x
    original_limit = configuration.contact_reminder_digest_preview_limit
    configuration.contact_reminder_digest_preview_limit = 1

    ContactReminderDigestEmailDelivery.call(digest_id: digest.id, at: @delivery_time, transport:)

    body = transport.message.text_part.body.to_s
    assert_includes body, people(:ada).name
    assert_not_includes body, people(:grace).name
    assert_includes body, "2"
  ensure
    configuration.contact_reminder_digest_preview_limit = original_limit
  end

  test "cancels stale members before sending the remaining people" do
    current = create_due_delivery(people(:ada))
    stale = create_due_delivery(people(:grace))
    digest = create_digest(current, stale)
    people(:grace).keep_in_touch_setting.disable!
    transport = RecordingTransport.new

    ContactReminderDigestEmailDelivery.call(digest_id: digest.id, at: @delivery_time, transport:)

    assert_equal ReminderDelivery::DELIVERED_STATUS, current.reload.status
    assert_equal ReminderDelivery::CANCELED_STATUS, stale.reload.status
    assert_includes transport.message.text_part.body.to_s, people(:ada).name
    assert_not_includes transport.message.text_part.body.to_s, people(:grace).name
  end

  test "cancels the digest without transport when every member is stale" do
    delivery = create_due_delivery(people(:ada))
    digest = create_digest(delivery)
    people(:ada).keep_in_touch_setting.disable!
    transport = RecordingTransport.new

    assert_nil ContactReminderDigestEmailDelivery.call(
      digest_id: digest.id, at: @delivery_time, transport:
    )

    assert_equal ContactReminderDigest::CANCELED_STATUS, digest.reload.status
    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
    assert_empty transport.messages
  end

  test "records a failed digest attempt and retries the same frozen membership" do
    delivery = create_due_delivery(people(:ada))
    digest = create_digest(delivery)

    assert_raises MailTransports::DeliveryError do
      ContactReminderDigestEmailDelivery.call(
        digest_id: digest.id, at: @delivery_time, transport: FailingTransport.new
      )
    end

    assert_equal ContactReminderDigest::FAILED_STATUS, digest.reload.status
    assert_equal 1, digest.attempts
    assert_equal ReminderDelivery::PENDING_STATUS, delivery.reload.status

    ContactReminderDigestEmailDelivery.call(
      digest_id: digest.id, at: @delivery_time + 1.minute, transport: RecordingTransport.new
    )

    assert_equal ContactReminderDigest::DELIVERED_STATUS, digest.reload.status
    assert_equal 2, digest.attempts
    assert_equal ReminderDelivery::DELIVERED_STATUS, delivery.reload.status
  end

  test "does not overwrite a newer digest outcome after its claim expires" do
    delivery = create_due_delivery(people(:ada))
    digest = create_digest(delivery)
    replaced_at = @delivery_time + 1.minute
    transport = ReplacingTransport.new(digest:, delivery:, replaced_at:)

    ContactReminderDigestEmailDelivery.call(digest_id: digest.id, at: @delivery_time, transport:)

    assert_equal replaced_at, digest.reload.delivered_at
    assert_equal replaced_at, delivery.reload.delivered_at
    assert_nil digest.claim_token
  end

  private

  def create_due_delivery(person)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: @delivery_on - 7.days)
    ReminderDelivery.create!(
      user: @user, source: person, channel: "email",
      reminder_on: @delivery_on, occurrence_on: @delivery_on
    )
  end

  def create_digest(*deliveries)
    digest = ContactReminderDigest.create!(user: @user, delivery_on: @delivery_on)
    deliveries.each { |delivery| delivery.update!(contact_reminder_digest: digest) }
    digest
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
    def initialize(digest:, delivery:, replaced_at:)
      @digest = digest
      @delivery = delivery
      @replaced_at = replaced_at
    end

    def deliver(message:, delivery_id:)
      @digest.update_columns(
        status: ContactReminderDigest::DELIVERED_STATUS,
        delivered_at: @replaced_at,
        claimed_at: nil,
        claim_token: nil,
        updated_at: @replaced_at
      )
      @delivery.update_columns(
        status: ReminderDelivery::DELIVERED_STATUS,
        delivered_at: @replaced_at,
        updated_at: @replaced_at
      )
      { identifier: "newer-delivery" }
    end
  end
end
