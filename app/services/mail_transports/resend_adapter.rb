module MailTransports
  class ResendAdapter
    def initialize(delivery_method: Resend::Mailer, api_key: Rails.application.config.x.resend_api_key)
      @delivery_method = delivery_method
      @api_key = api_key
    end

    def deliver(message:, delivery_id:)
      raise DeliveryError, "The Resend mail transport is missing its API key" if api_key.blank?

      Resend.api_key = api_key
      message.delivery_method(delivery_method)
      message["options"] = { idempotency_key: delivery_id.to_s }
      response = message.deliver!
      raise DeliveryError, "Resend rejected the mail delivery" if response[:error].present?

      { identifier: response[:id] }
    rescue DeliveryError
      raise
    rescue StandardError => error
      raise DeliveryError, "Resend mail delivery failed: #{error.class}"
    end

    private

    attr_reader :delivery_method, :api_key
  end
end
