module AccountImport
  class Document
    class InvalidDocument < StandardError
      attr_reader :code

      def initialize(code)
        @code = code
        super("invalid account import document: #{code}")
      end
    end

    ROOT_KEYS = %w[format_version generated_at account categories contact_methods people].freeze
    SUPPORTED_FORMAT_VERSIONS = [ 1 ].freeze

    attr_reader :payload

    def self.parse(json)
      payload = parse_json(json)
      validate_envelope!(payload)
      version = version_for(payload.fetch("format_version")).new(payload)
      version.validate!
      new(payload, version:)
    end

    def self.parse_json(json)
      JSON.parse(json)
    rescue JSON::ParserError, TypeError
      raise InvalidDocument, :invalid_json
    end

    def self.validate_envelope!(payload)
      return if payload.is_a?(Hash) && payload.keys.sort == ROOT_KEYS.sort

      raise InvalidDocument, :invalid_structure
    end

    def self.version_for(version)
      return Version1 if version == 1

      raise InvalidDocument, :unsupported_version
    end
    private_class_method :parse_json, :validate_envelope!, :version_for

    def initialize(payload, version:)
      @payload = payload
      @version = version
    end

    def source_email_address = payload.dig("account", "email_address")

    def entry_type_for(type) = version.entry_type_for(type)

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

    attr_reader :version

    def reminder_count(people)
      people.count { |person| person["keep_in_touch_setting"] } +
        people.sum { |person| person.fetch("entries").count { |entry| entry["reminder"] } }
    end
  end
end
