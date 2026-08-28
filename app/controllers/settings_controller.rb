class SettingsController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    attributes = settings_params
    contact_reminders_enabled = attributes.delete(:contact_reminders_enabled)
    @user.assign_attributes(attributes)
    apply_contact_reminder_enabled_state(contact_reminders_enabled) unless contact_reminders_enabled.nil?

    if save_settings
      redirect_to settings_path, notice: I18n.t("settings.update.updated", locale: demo_mode? ? I18n.default_locale : @user.locale)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def settings_params
    permitted_attributes = [
      :locale,
      :theme,
      :reminder_in_app_enabled,
      :reminder_email_enabled,
      :default_reminder_lead_value,
      :default_reminder_lead_unit,
      :birthday_reminders_enabled,
      :birthday_reminder_lead_value,
      :birthday_reminder_lead_unit,
      :contact_reminder_cadence,
      :contact_reminders_enabled
    ]
    permitted = params.expect(user: permitted_attributes)
    demo_mode? ? permitted.except(:locale) : permitted
  end

  def apply_contact_reminder_enabled_state(value)
    enabled = ActiveModel::Type::Boolean.new.cast(value)
    @user.contact_reminders_enabled_on = enabled ? (@user.contact_reminders_enabled_on || @user.local_date) : nil
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
