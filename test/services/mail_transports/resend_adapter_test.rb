require "test_helper"

class MailTransports::ResendAdapterTest < ActiveSupport::TestCase
  setup { @original_api_key = Resend.api_key }
  teardown { Resend.api_key = @original_api_key }

  test "passes the stable idempotency key through the Resend delivery method" do
    sent_options = nil
    send_email = lambda do |_params, options:|
      sent_options = options
      { id: "resend-message-id", error: nil }
    end

    result = with_resend_send(send_email) do
      adapter.deliver(message: mail_message, delivery_id: "reminder-delivery/43")
    end

    assert_equal({ idempotency_key: "reminder-delivery/43" }, sent_options)
    assert_equal({ identifier: "resend-message-id" }, result)
  end

  test "raises when the provider rejects the request" do
    send_email = lambda do |_params, options:|
      { id: nil, error: { name: "validation_error" } }
    end

    error = with_resend_send(send_email) do
      assert_raises(MailTransports::DeliveryError) do
        adapter.deliver(message: mail_message, delivery_id: "reminder-delivery/44")
      end
    end

    assert_equal "Resend rejected the mail delivery", error.message
  end

  test "requires a configured API key" do
    adapter = MailTransports::ResendAdapter.new(api_key: nil)

    error = assert_raises(MailTransports::DeliveryError) do
      adapter.deliver(message: Mail.new, delivery_id: "reminder-delivery/45")
    end

    assert_equal "The Resend mail transport is missing its API key", error.message
  end

  private

  def adapter
    MailTransports::ResendAdapter.new(api_key: "re_test")
  end

  def mail_message
    Mail.new do
      from "from@example.com"
      to "recipient@example.com"
      subject "Test message"
      body "Test body"
    end
  end

  def with_resend_send(replacement)
    original = Resend::Emails.method(:send)
    Resend::Emails.define_singleton_method(:send, replacement)
    yield
  ensure
    Resend::Emails.define_singleton_method(:send, original)
  end
end
