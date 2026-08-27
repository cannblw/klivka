class PersonContactActionsComponent < ViewComponent::Base
  DOM_ID = "person_contact_actions"
  INITIAL_ACTION_LIMIT = 2

  def initialize(entries:)
    @entries = entries
  end

  private

  attr_reader :entries

  def phone_entries
    @phone_entries ||= entries.select { |entry| entry.is_a?(Entry::Phone) && value_for(entry).present? }
  end

  def email_entries
    @email_entries ||= entries.select { |entry| entry.is_a?(Entry::Email) && value_for(entry).present? }
  end

  def contact_entries
    phone_entries + email_entries
  end

  def initial_entries_for(kind)
    entries_for(kind).first(INITIAL_ACTION_LIMIT)
  end

  def overflow?
    phone_entries.size > INITIAL_ACTION_LIMIT || email_entries.size > INITIAL_ACTION_LIMIT
  end

  def entries_for(kind)
    kind == :phone ? phone_entries : email_entries
  end

  def kind_for(entry)
    entry.is_a?(Entry::Phone) ? :phone : :email
  end

  def value_for(entry)
    entry.content&.dig(kind_for(entry) == :phone ? "number" : "email")
  end

  def label_for(entry)
    entry.content&.dig("label")
  end

  def href_for(entry)
    "#{kind_for(entry) == :phone ? "tel" : "mailto"}:#{value_for(entry)}"
  end

  def action_icon_for(entry)
    kind_for(entry) == :phone ? "call" : "email"
  end

  def action_label_for(entry)
    t("contact_actions.#{kind_for(entry)}", value: value_for(entry))
  end

  def copy_label_for(entry)
    t("contact_actions.copy_#{kind_for(entry)}", value: value_for(entry))
  end
end
