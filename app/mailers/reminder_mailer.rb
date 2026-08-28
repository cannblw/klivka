class ReminderMailer < ApplicationMailer
  def contact_digest
    @digest = params.fetch(:digest)
    @user = @digest.user
    @preview_people = params.fetch(:people)
    @contact_count = params.fetch(:count)
    @remaining_count = @contact_count - @preview_people.size
    @reminders_url = reminders_url
    @settings_url = settings_url

    I18n.with_locale(user.locale.presence || I18n.default_locale) do
      mail to: user.email_address,
        subject: t(".contact_digest.subject", count: @contact_count, name: @preview_people.first.name)
    end
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
  end

  def source_person
    source = delivery.source
    case source
    when EntryReminder then source.entry.person
    else source.person
    end
  end

  def mail_for_delivery
    I18n.with_locale(user.locale.presence || I18n.default_locale) do
      mail to: user.email_address, subject: yield
    end
  end
end
