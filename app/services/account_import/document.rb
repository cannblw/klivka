module AccountImport
  class Document
    class InvalidDocument < StandardError
      attr_reader :code

      def initialize(code)
        @code = code
        super("invalid account import document: #{code}")
      end
    end

    SUPPORTED_FORMAT_VERSIONS = [ 1 ].freeze

    attr_reader :payload

    def self.parse(json)
      payload = JSON.parse(json)
      validator_for(payload["format_version"]).new(payload).validate!
      new(payload)
    rescue JSON::ParserError, TypeError
      raise InvalidDocument, :invalid_json
    end

    def self.validator_for(version)
      return Version1Validator if version == 1

      raise InvalidDocument, :unsupported_version
    end
    private_class_method :validator_for

    def initialize(payload)
      @payload = payload
    end

    def source_email_address = payload.dig("account", "email_address")

    def summary
      people = payload.fetch("people")
      {
        "generated_at" => payload.fetch("generated_at"),
        "categories" => payload.fetch("categories").size,
        "contact_methods" => payload.fetch("contact_methods").size,
        "people" => people.size,
        "archived_people" => people.count { |person| person["archived_at"] },
        "entries" => people.sum { |person| person.fetch("entries").size },
        "interactions" => people.sum { |person| person.fetch("interactions").size },
        "reminders" => reminder_count(people)
      }
    end

    private

    def reminder_count(people)
      people.count { |person| person["keep_in_touch_setting"] } +
        people.sum { |person| person.fetch("entries").count { |entry| entry["reminder"] } }
    end
  end
end
