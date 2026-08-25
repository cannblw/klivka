class SettingsController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(settings_params)
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
      :birthday_reminder_lead_unit
    ]
    permitted = params.expect(user: permitted_attributes)
    demo_mode? ? permitted.except(:locale) : permitted
  end
end
