class PeopleFilter
  def initialize(user, filters:, on:)
    @user = user
    @filters = filters
    @on = on
  end

  def call
    scope = people_for_state
    scope = filter_by_category(scope)
    scope = filter_by_birthday(scope)
    scope = filter_by_last_contact(scope)
    scope = filter_by_blocks(scope)
    scope = filter_by_contact_reminder(scope)
    filter_by_date_reminder(scope)
  end

  private

  attr_reader :filters, :on, :user

  def people_for_state
    case filters[:state]
    when "archived" then user.people.archived
    when "all" then user.people
    else user.people.active
    end
  end

  def filter_by_category(scope)
    case filters[:category]
    when PeopleQuery::UNCATEGORIZED_FILTER then scope.where(category_id: nil)
    when nil then scope
    else scope.where(category_id: filters[:category])
    end
  end

  def filter_by_birthday(scope)
    birthday_people = Entry::Birthday.where(person_id: tenant_person_ids)
    case filters[:birthday]
    when "missing" then scope.where.not(id: birthday_people.select(:person_id))
    when "year_unknown" then scope.where(id: birthday_people.where(birthday_year_known: false).select(:person_id))
    else scope
    end
  end

  def filter_by_last_contact(scope)
    interactions = Interaction.where(person_id: tenant_person_ids)
    return scope.where.not(id: interactions.select(:person_id)) if filters[:last_contact] == "never"
    return scope unless filters[:last_contact]

    latest_interaction = Interaction.arel_table[:occurred_on].maximum
    latest_interactions = interactions.group(:person_id)
    latest_interactions = case filters[:last_contact]
    when "within_30_days" then latest_interactions.having(latest_interaction.between((on - 30.days)..on))
    when "31_to_90_days" then latest_interactions.having(latest_interaction.between((on - 90.days)..(on - 31.days)))
    when "91_to_180_days" then latest_interactions.having(latest_interaction.between((on - 180.days)..(on - 91.days)))
    when "over_180_days" then latest_interactions.having(latest_interaction.lt(on - 180.days))
    end
    scope.where(id: latest_interactions.select(:person_id))
  end

  def filter_by_blocks(scope)
    filters[:has_blocks].each do |block|
      entries = Entry.where(person_id: tenant_person_ids, type: PeopleQuery::BLOCK_TYPES.fetch(block))
      scope = scope.where(id: entries.select(:person_id))
    end
    filters[:missing_blocks].each do |block|
      entries = Entry.where(person_id: tenant_person_ids, type: PeopleQuery::BLOCK_TYPES.fetch(block))
      scope = scope.where.not(id: entries.select(:person_id))
    end
    scope
  end

  def filter_by_contact_reminder(scope)
    return scope unless filters[:contact_reminder]

    settings = KeepInTouchSetting.where(person_id: tenant_person_ids)
    enabled_settings = settings.where.not(enabled_on: nil)
    disabled_settings = settings.where(enabled_on: nil)
    if user.contact_reminders_enabled?
      filters[:contact_reminder] == "on" ?
        scope.where.not(id: disabled_settings.select(:person_id)) :
        scope.where(id: disabled_settings.select(:person_id))
    elsif filters[:contact_reminder] == "on"
      scope.where(id: enabled_settings.select(:person_id))
    else
      scope.where.not(id: enabled_settings.select(:person_id))
    end
  end

  def filter_by_date_reminder(scope)
    return scope unless filters[:date_reminder]

    dates = Entry.where(person_id: tenant_person_ids, type: Entry::Date.sti_name)
    reminded_entry_ids = EntryReminder.select(:entry_id)
    dates = filters[:date_reminder] == "present" ? dates.where(id: reminded_entry_ids) : dates.where.not(id: reminded_entry_ids)
    scope.where(id: dates.select(:person_id))
  end

  def tenant_person_ids
    @tenant_person_ids ||= user.people.select(:id)
  end
end
