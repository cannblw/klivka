class SettingsController < ApplicationController
  before_action :set_user

  def show
  end

  def preferences
  end

  def reminders
  end

  def update_preferences
    @user.assign_attributes(preference_params)

    if @user.save
      redirect_to settings_preferences_path, notice: settings_updated_notice
    else
      render :preferences, status: :unprocessable_entity
    end
  end

  def update_reminders
    attributes = reminder_params
    contact_reminders_enabled = attributes.delete(:contact_reminders_enabled)
    schedule_attributes = attributes.extract!(*ContactReminderSchedule::PARAMETER_KEYS)
    original_cadence = @user.contact_reminder_cadence
    was_enabled = @user.contact_reminders_enabled?
    @user.assign_attributes(attributes)
    apply_contact_reminder_policy(
      enabled_value: contact_reminders_enabled,
      schedule_attributes:,
      original_cadence:,
      was_enabled:
    )

    if save_settings
      redirect_to settings_reminders_path, notice: settings_updated_notice
    else
      render :reminders, status: :unprocessable_entity
    end
  rescue ContactReminder::InvalidSchedule
    @user.errors.add(:contact_reminder_first_reminder_on, :invalid)
    render :reminders, status: :unprocessable_entity
  end

  private

  def set_user
    @user = Current.user
  end

  def preference_params
    permitted = params.expect(user: %i[ locale theme ])
    demo_mode? ? permitted.except(:locale) : permitted
  end

  def reminder_params
    params.expect(user: [
      :reminder_in_app_enabled,
      :reminder_email_enabled,
      :default_reminder_lead_value,
      :default_reminder_lead_unit,
      :birthday_reminders_enabled,
      :birthday_reminder_lead_value,
      :birthday_reminder_lead_unit,
      :contact_reminder_cadence,
      :contact_reminders_enabled,
      *ContactReminderSchedule::PARAMETER_KEYS
    ])
  end

  def settings_updated_notice
    I18n.t("settings.update.updated", locale: demo_mode? ? I18n.default_locale : @user.locale)
  end

  def apply_contact_reminder_policy(enabled_value:, schedule_attributes:, original_cadence:, was_enabled:)
    enabled = enabled_value.nil? ? was_enabled : ActiveModel::Type::Boolean.new.cast(enabled_value)
    if enabled
      schedule = contact_reminder_schedule(schedule_attributes)
      schedule_changed = !was_enabled || original_cadence != @user.contact_reminder_cadence ||
        schedule.changed?
      return unless schedule_changed

      @user.contact_reminders_enabled_on = @user.local_date
      @user.contact_reminder_first_reminder_on = schedule.first_reminder_on
    else
      @user.contact_reminders_enabled_on = nil
      @user.contact_reminder_first_reminder_on = nil
    end
  end

  def contact_reminder_schedule(attributes)
    ContactReminderSchedule.new(
      cadence: @user.contact_reminder_cadence,
      on: @user.local_date,
      attributes:
    )
  end

  def save_settings
    saved = false

    @user.transaction do
      unless @user.save
        raise ActiveRecord::Rollback
      end

      clear_inherited_snoozes if contact_reminder_policy_changed?
      saved = true
    end

    saved
  end

  def contact_reminder_policy_changed?
    @user.saved_change_to_contact_reminder_cadence? || @user.saved_change_to_contact_reminders_enabled_on?
  end

  def clear_inherited_snoozes
    @user.people.where.missing(:keep_in_touch_setting).where.not(contact_reminder_snoozed_until: nil)
      .update_all(contact_reminder_snoozed_until: nil)
  end
end
