class ReminderMailer < ApplicationMailer
  def keep_in_touch
    prepare_delivery
    mail_for_delivery { t(".keep_in_touch.subject", name: person.name) }
  end

  def birthday
    prepare_delivery
    mail_for_delivery { t(".birthday.subject", name: person.name) }
  end

  def significant_date
    prepare_delivery
    mail_for_delivery do
      @label = entry.label.presence || t(".significant_date.default_label")
      t(".significant_date.subject", name: person.name, label: @label)
    end
  end

  private

  attr_reader :delivery, :entry, :person, :user

  def prepare_delivery
    @delivery = params.fetch(:delivery)
    @user = delivery.user
    @person = source_person
    @entry = delivery.source.entry if delivery.source.is_a?(EntryReminder)
    @entry = delivery.source if delivery.source.is_a?(Entry::Birthday)
    @occurrence_on = delivery.occurrence_on
    @person_url = person_url(person)
    @settings_url = settings_url
    @contact_url = person_url(
      person,
      quick_interaction: "today",
      anchor: QuickInteractionComponent::DOM_ID
    ) if delivery.source.is_a?(KeepInTouchSetting)
  end

  def source_person
    source = delivery.source
    source.is_a?(EntryReminder) ? source.entry.person : source.person
  end

  def mail_for_delivery
    I18n.with_locale(user.locale.presence || I18n.default_locale) do
      mail to: user.email_address, subject: yield
    end
  end
end
