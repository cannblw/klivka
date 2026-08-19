class ReminderMailer < ApplicationMailer
  layout "reminder_mailer"

  def keep_in_touch
    prepare_delivery
    mail_for_delivery { t(".keep_in_touch.subject", name: friend.name) }
  end

  def birthday
    prepare_delivery
    mail_for_delivery { t(".birthday.subject", name: friend.name) }
  end

  def significant_date
    prepare_delivery
    mail_for_delivery do
      @label = entry.label.presence || t(".significant_date.default_label")
      t(".significant_date.subject", name: friend.name, label: @label)
    end
  end

  private

  attr_reader :delivery, :entry, :friend, :user

  def prepare_delivery
    @delivery = params.fetch(:delivery)
    @user = delivery.user
    @friend = source_friend
    @entry = delivery.source.entry if delivery.source.is_a?(EntryReminder)
    @occurrence_on = delivery.occurrence_on
    @logo_url = "#{Rails.application.config.x.application_url}/brand/klivka-logo.svg"
    @friend_url = friend_url(friend)
    @settings_url = settings_url
    @contact_url = friend_url(
      friend,
      quick_interaction: "today",
      anchor: QuickInteractionComponent::DOM_ID
    ) if delivery.source.is_a?(KeepInTouchSetting)
  end

  def source_friend
    source = delivery.source
    source.is_a?(KeepInTouchSetting) ? source.friend : source.entry.friend
  end

  def mail_for_delivery
    I18n.with_locale(user.locale.presence || I18n.default_locale) do
      mail to: user.email_address, subject: yield
    end
  end
end
