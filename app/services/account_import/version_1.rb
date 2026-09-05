module AccountImport
  class Version1
    ACCOUNT_KEYS = %w[
      email_address locale theme time_zone reminder_in_app_enabled reminder_email_enabled
      default_reminder_lead_value default_reminder_lead_unit birthday_reminders_enabled
      birthday_reminder_lead_value birthday_reminder_lead_unit contact_reminder_cadence
      contact_reminders_enabled_on contact_reminder_first_reminder_on created_at updated_at
    ].freeze
    CATEGORY_KEYS = %w[name created_at updated_at].freeze
    CONTACT_METHOD_KEYS = %w[
      name icon_library icon_name enabled provided position created_at updated_at
    ].freeze
    PERSON_KEYS = %w[
      name slug category archived_at contact_reminder_snoozed_until created_at updated_at
      keep_in_touch_setting entries interactions
    ].freeze
    KEEP_IN_TOUCH_KEYS = %w[cadence enabled_on first_reminder_on created_at updated_at].freeze
    ENTRY_KEYS = %w[
      type position content entry_date birthday_year_known created_at updated_at reminder
    ].freeze
    ENTRY_REMINDER_KEYS = %w[lead_value lead_unit recurrence created_at updated_at].freeze
    INTERACTION_KEYS = %w[
      occurred_on contact_method_name contact_method_icon_library contact_method_icon_name note
      created_at updated_at
    ].freeze
    ENTRY_TYPES = {
      "birthday" => "Entry::Birthday",
      "date" => "Entry::Date",
      "email" => "Entry::Email",
      "first_met" => "Entry::FirstMet",
      "gift_list" => "Entry::GiftList",
      "note" => "Entry::Note",
      "phone" => "Entry::Phone"
    }.freeze
    DATE_ENTRY_TYPES = %w[birthday date first_met].freeze

    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def validate!
      invalid!(:unsupported_version) unless payload["format_version"] == 1
      timestamp!(payload["generated_at"])
      validate_account(payload["account"])
      validate_categories(payload["categories"])
      validate_contact_methods(payload["contact_methods"])
      validate_people(payload["people"])
      self
    rescue ArgumentError, TypeError, TZInfo::InvalidTimezoneIdentifier
      invalid!(:invalid_value)
    end

    def entry_type_for(type) = ENTRY_TYPES.fetch(type)

    private

    def validate_account(account)
      object!(account, ACCOUNT_KEYS)
      string!(account["email_address"])
      invalid!(:invalid_value) unless account["email_address"].match?(URI::MailTo::EMAIL_REGEXP)
      nullable_string!(account["locale"])
      nullable_string!(account["theme"])
      invalid!(:invalid_value) unless account["locale"].nil? || I18n.available_locales.map(&:to_s).include?(account["locale"])
      invalid!(:invalid_value) unless account["theme"].nil? || %w[light dark].include?(account["theme"])
      string!(account["time_zone"])
      TZInfo::Timezone.get(account["time_zone"])
      boolean!(account["reminder_in_app_enabled"])
      boolean!(account["reminder_email_enabled"])
      reminder_lead!(account["default_reminder_lead_value"], account["default_reminder_lead_unit"])
      boolean!(account["birthday_reminders_enabled"])
      reminder_lead!(account["birthday_reminder_lead_value"], account["birthday_reminder_lead_unit"])
      invalid!(:invalid_value) unless ContactReminder::CADENCES.include?(account["contact_reminder_cadence"])
      enabled_on = nullable_date!(account["contact_reminders_enabled_on"])
      first_reminder_on = nullable_date!(account["contact_reminder_first_reminder_on"])
      invalid!(:invalid_value) unless reminder_dates_consistent?(enabled_on, first_reminder_on)
      timestamps!(account)
    end

    def validate_categories(categories)
      array!(categories)
      categories.each do |category|
        object!(category, CATEGORY_KEYS)
        string!(category["name"])
        timestamps!(category)
      end
      unique_normalized_names!(categories)
    end

    def validate_contact_methods(contact_methods)
      array!(contact_methods)
      contact_methods.each do |contact_method|
        object!(contact_method, CONTACT_METHOD_KEYS)
        string!(contact_method["name"])
        nullable_string!(contact_method["icon_library"])
        nullable_string!(contact_method["icon_name"])
        invalid!(:invalid_value) unless ContactMethodIcons.valid?(
          contact_method["icon_library"], contact_method["icon_name"]
        )
        boolean!(contact_method["enabled"])
        boolean!(contact_method["provided"])
        position = contact_method["position"]
        contact_method["enabled"] ? nonnegative_integer!(position) : nil!(position)
        timestamps!(contact_method)
      end
      unique_normalized_names!(contact_methods)
    end

    def validate_people(people)
      array!(people)
      category_names = payload.fetch("categories").pluck("name")
      slugs = []

      people.each do |person|
        object!(person, PERSON_KEYS)
        string!(person["name"])
        string!(person["slug"])
        category = person["category"]
        invalid!(:invalid_reference) unless category.nil? || category_names.include?(category)
        nullable_timestamp!(person["archived_at"])
        nullable_date!(person["contact_reminder_snoozed_until"])
        timestamps!(person)
        validate_keep_in_touch_setting(person["keep_in_touch_setting"])
        validate_entries(person["entries"])
        validate_interactions(person["interactions"])
        slugs << person["slug"]
      end

      invalid!(:duplicate_value) unless slugs.uniq.size == slugs.size
    end

    def validate_keep_in_touch_setting(setting)
      return if setting.nil?

      object!(setting, KEEP_IN_TOUCH_KEYS)
      invalid!(:invalid_value) unless ContactReminder::CADENCES.include?(setting["cadence"])
      enabled_on = nullable_date!(setting["enabled_on"])
      first_reminder_on = nullable_date!(setting["first_reminder_on"])
      invalid!(:invalid_value) unless reminder_dates_consistent?(enabled_on, first_reminder_on)
      timestamps!(setting)
    end

    def validate_entries(entries)
      array!(entries)
      singleton_types = []

      entries.each do |entry|
        object!(entry, ENTRY_KEYS)
        type = entry["type"]
        invalid!(:unsupported_entry_type) unless ENTRY_TYPES.key?(type)
        nonnegative_integer!(entry["position"])
        invalid!(:invalid_value) unless entry["content"].is_a?(Hash)
        validate_entry_date_fields(entry)
        timestamps!(entry)
        validate_entry_reminder(entry["reminder"], type:)
        singleton_types << type if %w[birthday first_met].include?(type)
      end

      invalid!(:duplicate_value) unless singleton_types.uniq.size == singleton_types.size
    end

    def validate_entry_date_fields(entry)
      if DATE_ENTRY_TYPES.include?(entry["type"])
        date!(entry["entry_date"])
      else
        nil!(entry["entry_date"])
      end

      if entry["type"] == "birthday"
        boolean!(entry["birthday_year_known"])
      else
        nil!(entry["birthday_year_known"])
      end
    end

    def validate_entry_reminder(reminder, type:)
      return if reminder.nil?

      invalid!(:invalid_value) unless type == "date"
      object!(reminder, ENTRY_REMINDER_KEYS)
      reminder_lead!(reminder["lead_value"], reminder["lead_unit"])
      invalid!(:invalid_value) unless EntryReminder::RECURRENCES.include?(reminder["recurrence"])
      timestamps!(reminder)
    end

    def validate_interactions(interactions)
      array!(interactions)
      interactions.each do |interaction|
        object!(interaction, INTERACTION_KEYS)
        date!(interaction["occurred_on"])
        nullable_string!(interaction["contact_method_name"])
        nullable_string!(interaction["contact_method_icon_library"])
        nullable_string!(interaction["contact_method_icon_name"])
        nullable_string!(interaction["note"])
        icon_values = interaction.values_at("contact_method_icon_library", "contact_method_icon_name")
        invalid!(:invalid_value) unless icon_values.all?(&:nil?) || interaction["contact_method_name"] && icon_values.all?(&:present?)
        timestamps!(interaction)
      end
    end

    def unique_normalized_names!(records)
      names = records.map { |record| StringNormalizer.call(record["name"]).downcase }
      invalid!(:duplicate_value) unless names.uniq.size == names.size
    end

    def reminder_lead!(value, unit)
      nonnegative_integer!(value)
      invalid!(:invalid_value) if value > Klivka::MAX_INT32
      invalid!(:invalid_value) unless User::REMINDER_LEAD_UNITS.key?(unit)
    end

    def reminder_dates_consistent?(enabled_on, first_reminder_on)
      (enabled_on.nil? && first_reminder_on.nil?) ||
        (enabled_on.present? && first_reminder_on.present? && first_reminder_on > enabled_on)
    end

    def timestamps!(record)
      timestamp!(record["created_at"])
      timestamp!(record["updated_at"])
    end

    def object!(value, keys)
      invalid!(:invalid_structure) unless value.is_a?(Hash) && value.keys.sort == keys.sort
    end

    def array!(value)
      invalid!(:invalid_structure) unless value.is_a?(Array)
    end

    def string!(value)
      invalid!(:invalid_value) unless value.is_a?(String) && value.present?
    end

    def nullable_string!(value)
      invalid!(:invalid_value) unless value.nil? || value.is_a?(String)
    end

    def boolean!(value)
      invalid!(:invalid_value) unless value == true || value == false
    end

    def nonnegative_integer!(value)
      invalid!(:invalid_value) unless value.is_a?(Integer) && value >= 0
    end

    def nil!(value)
      invalid!(:invalid_value) unless value.nil?
    end

    def date!(value)
      string!(value)
      Date.iso8601(value)
    end

    def nullable_date!(value)
      return if value.nil?

      date!(value)
    end

    def timestamp!(value)
      string!(value)
      Time.iso8601(value)
    end

    def nullable_timestamp!(value)
      timestamp!(value) unless value.nil?
    end

    def invalid!(code)
      raise Document::InvalidDocument, code
    end
  end
end
