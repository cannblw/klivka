module MailTransports
  class RailsAdapter
    def deliver(message:, delivery_id:)
      message["X-Klivka-Delivery-ID"] = delivery_id.to_s
      message.deliver!
      { identifier: message.message_id }
    rescue StandardError => error
      raise DeliveryError, "Rails mail delivery failed: #{error.class}"
    end
  end
end
