require "test_helper"

class ReminderDeliveryEmailJobTest < ActiveJob::TestCase
  test "finishes safely when account deletion removed the delivery work" do
    assert_nothing_raised { ReminderDeliveryEmailJob.perform_now(-1) }
  end

  test "retries a failed individual date email with only its ledger identifier" do
    delivery = ReminderDelivery.create!(
      user: users(:one), source: entries(:ada_birthday), channel: "email",
      reminder_on: Date.new(2026, 11, 10), occurrence_on: Date.new(2026, 12, 10)
    )

    with_failing_transport do
      assert_enqueued_with(job: ReminderDeliveryEmailJob, args: [ delivery.id ]) do
        ReminderDeliveryEmailJob.perform_now(delivery.id)
      end
    end

    assert_equal ReminderDelivery::FAILED_STATUS, delivery.reload.status
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
