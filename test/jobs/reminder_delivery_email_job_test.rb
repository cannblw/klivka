require "test_helper"

class ReminderDeliveryEmailJobTest < ActiveJob::TestCase
  test "retries a failed transport attempt with only the stable ledger identifier" do
    user = users(:one)
    local_date = user.local_date
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: local_date - 7.days)
    delivery = ReminderDelivery.create!(
      user:, source: setting.person, channel: "email", reminder_on: local_date, occurrence_on: local_date
    )

    with_failing_transport do
      assert_enqueued_with(job: ReminderDeliveryEmailJob, args: [ delivery.id ]) do
        ReminderDeliveryEmailJob.perform_now(delivery.id)
      end
    end

    assert_equal "failed", delivery.reload.status
    assert_equal 1, delivery.attempts
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
