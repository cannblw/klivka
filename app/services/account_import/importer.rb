module AccountImport
  class Importer
    ACCOUNT_ATTRIBUTES = %w[
      locale theme time_zone reminder_in_app_enabled reminder_email_enabled
      default_reminder_lead_value default_reminder_lead_unit birthday_reminders_enabled
      birthday_reminder_lead_value birthday_reminder_lead_unit contact_reminder_cadence
      contact_reminders_enabled_on contact_reminder_first_reminder_on
    ].freeze

    def self.call(user:, document:)
      new(user:, document:).call
    end

    def initialize(user:, document:)
      @user = user
      @document = document
    end

    def call
      user.transaction do
        user.lock!
        original_updated_at = user.updated_at

        remove_existing_data
        restore_account
        categories = restore_categories
        restore_contact_methods
        Person.no_touching { restore_people(categories:) }

        user.update_column(:updated_at, original_updated_at)
      end

      user.reload
    end

    private

    attr_reader :user, :document

    def payload = document.payload

    def remove_existing_data
      user.reminder_deliveries.delete_all
      user.contact_reminder_digests.delete_all
      user.vcard_imports.delete_all
      user.people.destroy_all
      user.categories.destroy_all
      user.contact_methods.destroy_all
      user.update_column(:reminders_scanned_through_on, nil)
    end

    def restore_account
      user.update!(payload.fetch("account").slice(*ACCOUNT_ATTRIBUTES))
    end

    def restore_categories
      payload.fetch("categories").to_h do |attributes|
        category = user.categories.create!(record_attributes(attributes, %w[name]))
        [ attributes.fetch("name"), category ]
      end
    end

    def restore_contact_methods
      payload.fetch("contact_methods").each do |attributes|
        user.contact_methods.create!(record_attributes(
          attributes,
          %w[name icon_library icon_name enabled provided position]
        ))
      end
    end

    def restore_people(categories:)
      payload.fetch("people").each do |attributes|
        person = user.people.create!(record_attributes(
          attributes,
          %w[name slug archived_at contact_reminder_snoozed_until]
        ).merge(category: categories[attributes["category"]]))

        restore_keep_in_touch_setting(person, attributes["keep_in_touch_setting"])
        restore_entries(person, attributes.fetch("entries"))
        restore_interactions(person, attributes.fetch("interactions"))
        restore_timestamps(person, attributes)
      end
    end

    def restore_keep_in_touch_setting(person, attributes)
      return unless attributes

      person.create_keep_in_touch_setting!(record_attributes(
        attributes,
        %w[cadence enabled_on first_reminder_on]
      ))
    end

    def restore_entries(person, entries)
      entries.each do |attributes|
        entry = person.entries.create!(record_attributes(
          attributes,
          %w[position content entry_date birthday_year_known]
        ).merge(type: document.entry_type_for(attributes.fetch("type"))))

        restore_entry_reminder(entry, attributes["reminder"])
      end
    end

    def restore_entry_reminder(entry, attributes)
      return unless attributes

      entry.create_entry_reminder!(record_attributes(attributes, %w[lead_value lead_unit recurrence]))
    end

    def restore_interactions(person, interactions)
      interactions.each do |attributes|
        interaction = person.interactions.new(record_attributes(
          attributes,
          %w[occurred_on contact_method_name contact_method_icon_library contact_method_icon_name note]
        ))
        interaction.validation_date = user.local_date
        interaction.save!
      end
    end

    def record_attributes(attributes, keys)
      attributes.slice(*keys).merge(
        "created_at" => Time.iso8601(attributes.fetch("created_at")),
        "updated_at" => Time.iso8601(attributes.fetch("updated_at"))
      )
    end

    def restore_timestamps(record, attributes)
      record.update_columns(
        created_at: Time.iso8601(attributes.fetch("created_at")),
        updated_at: Time.iso8601(attributes.fetch("updated_at"))
      )
    end
  end
end
