require "test_helper"

class ContactReminderDigestEmailJobTest < ActiveJob::TestCase
  test "retries a failed digest with only its stable identifier" do
    user = users(:one)
    digest = ContactReminderDigest.create!(user:, delivery_on: user.local_date)
    person = people(:ada)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: user.local_date - 7.days)
    ReminderDelivery.create!(
      user:, source: person, channel: "email", contact_reminder_digest: digest,
      reminder_on: user.local_date, occurrence_on: user.local_date
    )

    with_failing_transport do
      assert_enqueued_with(job: ContactReminderDigestEmailJob, args: [ digest.id ]) do
        ContactReminderDigestEmailJob.perform_now(digest.id)
      end
    end

    assert_equal ContactReminderDigest::FAILED_STATUS, digest.reload.status
    assert_equal 1, digest.attempts
  end

  private

  def with_failing_transport
    original_fetch = MailTransports.method(:fetch)
    MailTransports.define_singleton_method(:fetch) { |_name| FailingTransport.new }
    yield
  ensure
    MailTransports.define_singleton_method(:fetch, original_fetch)
  end

  class FailingTransport
    def deliver(message:, delivery_id:)
      raise MailTransports::DeliveryError, "provider unavailable"
    end
  end
end
