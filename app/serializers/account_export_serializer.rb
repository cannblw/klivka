class AccountExportSerializer
  FORMAT_VERSION = 1

  ENTRY_TYPES = {
    "Entry::Birthday" => "birthday",
    "Entry::Date" => "date",
    "Entry::Email" => "email",
    "Entry::FirstMet" => "first_met",
    "Entry::GiftList" => "gift_list",
    "Entry::Note" => "note",
    "Entry::Phone" => "phone"
  }.freeze

  def initialize(user:, generated_at: Time.current)
    @user = user
    @generated_at = generated_at
  end

  def as_json(*)
    {
      "format_version" => FORMAT_VERSION,
      "generated_at" => timestamp(generated_at),
      "account" => account,
      "categories" => categories,
      "contact_methods" => contact_methods,
      "people" => people
    }
  end

  private

  attr_reader :user, :generated_at

  def account
    {
      "email_address" => user.email_address,
      "locale" => user.locale,
      "theme" => user.theme,
      "time_zone" => user.time_zone,
      "reminder_in_app_enabled" => user.reminder_in_app_enabled,
      "reminder_email_enabled" => user.reminder_email_enabled,
      "default_reminder_lead_value" => user.default_reminder_lead_value,
      "default_reminder_lead_unit" => user.default_reminder_lead_unit,
      "birthday_reminders_enabled" => user.birthday_reminders_enabled,
      "birthday_reminder_lead_value" => user.birthday_reminder_lead_value,
      "birthday_reminder_lead_unit" => user.birthday_reminder_lead_unit,
      "contact_reminder_cadence" => user.contact_reminder_cadence,
      "contact_reminders_enabled_on" => date(user.contact_reminders_enabled_on),
      "contact_reminder_first_reminder_on" => date(user.contact_reminder_first_reminder_on),
      "created_at" => timestamp(user.created_at),
      "updated_at" => timestamp(user.updated_at)
    }
  end

  def categories
    user.categories.order(:id).map do |category|
      {
        "name" => category.name,
        "created_at" => timestamp(category.created_at),
        "updated_at" => timestamp(category.updated_at)
      }
    end
  end

  def contact_methods
    user.contact_methods.order(:id).map do |contact_method|
      {
        "name" => contact_method.name,
        "icon_library" => contact_method.icon_library,
        "icon_name" => contact_method.icon_name,
        "enabled" => contact_method.enabled,
        "provided" => contact_method.provided,
        "position" => contact_method.position,
        "created_at" => timestamp(contact_method.created_at),
        "updated_at" => timestamp(contact_method.updated_at)
      }
    end
  end

  def people
    user.people
      .includes(:category, :keep_in_touch_setting, :interactions, entries: :entry_reminder)
      .order(:id)
      .map { |person| person_payload(person) }
  end

  def person_payload(person)
    {
      "name" => person.name,
      "slug" => person.slug,
      "category" => person.category&.name,
      "archived_at" => timestamp(person.archived_at),
      "contact_reminder_snoozed_until" => date(person.contact_reminder_snoozed_until),
      "created_at" => timestamp(person.created_at),
      "updated_at" => timestamp(person.updated_at),
      "keep_in_touch_setting" => keep_in_touch_setting(person.keep_in_touch_setting),
      "entries" => person.entries.sort_by { |entry| [ entry.position, entry.id ] }.map { |entry| entry_payload(entry) },
      "interactions" => person.interactions.sort_by(&:id).map { |interaction| interaction_payload(interaction) }
    }
  end

  def keep_in_touch_setting(setting)
    return unless setting

    {
      "cadence" => setting.cadence,
      "enabled_on" => date(setting.enabled_on),
      "first_reminder_on" => date(setting.first_reminder_on),
      "created_at" => timestamp(setting.created_at),
      "updated_at" => timestamp(setting.updated_at)
    }
  end

  def entry_payload(entry)
    {
      "type" => ENTRY_TYPES.fetch(entry.type),
      "position" => entry.position,
      "content" => entry.content || {},
      "entry_date" => date(entry.entry_date),
      "birthday_year_known" => entry.birthday_year_known,
      "created_at" => timestamp(entry.created_at),
      "updated_at" => timestamp(entry.updated_at),
      "reminder" => entry_reminder(entry.entry_reminder)
    }
  end

  def entry_reminder(reminder)
    return unless reminder

    {
      "lead_value" => reminder.lead_value,
      "lead_unit" => reminder.lead_unit,
      "recurrence" => reminder.recurrence,
      "created_at" => timestamp(reminder.created_at),
      "updated_at" => timestamp(reminder.updated_at)
    }
  end

  def interaction_payload(interaction)
    {
      "occurred_on" => date(interaction.occurred_on),
      "contact_method_name" => interaction.contact_method_name,
      "contact_method_icon_library" => interaction.contact_method_icon_library,
      "contact_method_icon_name" => interaction.contact_method_icon_name,
      "note" => interaction.note,
      "created_at" => timestamp(interaction.created_at),
      "updated_at" => timestamp(interaction.updated_at)
    }
  end

  def date(value)
    value&.iso8601
  end

  def timestamp(value)
    value&.utc&.iso8601(6)
  end
end
