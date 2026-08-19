require "test_helper"

class MailTransports::RailsAdapterTest < ActiveSupport::TestCase
  test "adds a stable delivery header and returns the message identifier" do
    delivered_message = nil
    delivery_method = Class.new do
      attr_reader :settings

      define_method(:initialize) { |_settings| @settings = {} }
      define_method(:deliver!) do |message|
        delivered_message = message
        message.message_id = "rails-message-id"
      end
    end
    message = Mail.new
    message.delivery_method(delivery_method)

    result = MailTransports::RailsAdapter.new.deliver(message:, delivery_id: "reminder-delivery/42")

    assert_equal "reminder-delivery/42", delivered_message["X-Klivka-Delivery-ID"].to_s
    assert_equal({ identifier: "rails-message-id" }, result)
  end
end
