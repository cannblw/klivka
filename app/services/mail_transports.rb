module MailTransports
  class UnsupportedTransport < StandardError; end
  class DeliveryError < StandardError; end

  class << self
    def register(name, adapter)
      raise ArgumentError, "Mail transport adapters must implement deliver" unless adapter.respond_to?(:deliver)

      registry[name.to_s] = adapter
    end

    def fetch(name)
      registry.fetch(name.to_s) do
        raise UnsupportedTransport, "Unsupported mail transport: #{name}"
      end
    end

    def names
      registry.keys
    end

    private

    def registry
      @registry ||= {}
    end
  end
end
