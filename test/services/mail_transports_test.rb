require "test_helper"

class MailTransportsTest < ActiveSupport::TestCase
  test "registers every built-in mail transport" do
    assert_equal %w[rails resend], MailTransports.names.sort
    assert_instance_of MailTransports::RailsAdapter, MailTransports.fetch("rails")
    assert_instance_of MailTransports::ResendAdapter, MailTransports.fetch("resend")
  end

  test "mail transport registry accepts another adapter" do
    adapter = Object.new.tap { _1.define_singleton_method(:deliver) { } }

    MailTransports.register("custom", adapter)

    assert_same adapter, MailTransports.fetch("custom")
  ensure
    MailTransports.send(:registry).delete("custom")
  end

  test "mail transport registry rejects an object without the adapter contract" do
    error = assert_raises(ArgumentError) do
      MailTransports.register("invalid", Object.new)
    end

    assert_equal "Mail transport adapters must implement deliver", error.message
  end

  test "mail transport registry rejects an unsupported adapter" do
    error = assert_raises(MailTransports::UnsupportedTransport) do
      MailTransports.fetch("unknown")
    end

    assert_equal "Unsupported mail transport: unknown", error.message
  end
end
