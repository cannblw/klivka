class SettingsController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(settings_params)
      redirect_to settings_path
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def settings_params
    params.expect(user: [ :locale, :theme ])
  end
end
