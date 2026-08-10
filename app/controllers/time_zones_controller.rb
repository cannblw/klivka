class TimeZonesController < ApplicationController
  def update
    if Current.user.update(time_zone: time_zone)
      redirect_back_or_to root_path, notice: t(".updated")
    else
      redirect_back_or_to settings_path, alert: t(".invalid", reason: Current.user.errors.full_messages.to_sentence)
    end
  end

  private

  def time_zone
    params.expect(:time_zone)
  end
end
