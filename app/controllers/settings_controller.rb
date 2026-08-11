class SettingsController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(settings_params)
      redirect_to settings_path, notice: I18n.t("settings.update.updated", locale: @user.locale)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def settings_params
    params.expect(user: [
      :locale,
      :theme,
      :reminder_in_app_enabled,
      :reminder_email_enabled,
      :default_reminder_lead_value,
      :default_reminder_lead_unit
    ])
  end
end
