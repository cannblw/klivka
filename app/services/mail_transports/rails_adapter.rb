module MailTransports
  class RailsAdapter
    def deliver(message:, delivery_id:)
      message["X-Klivka-Delivery-ID"] = delivery_id.to_s
      message.deliver!
      { identifier: message.message_id }
    end
  end
end
