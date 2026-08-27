class KeepInTouchSettingsController < ApplicationController
  before_action :set_person
  before_action :set_keep_in_touch_setting, only: %i[ update enable disable snooze ]

  def create
    return redirect_to @person, alert: t(".stale") if @person.keep_in_touch_setting.present?

    @keep_in_touch_setting = @person.build_keep_in_touch_setting(setting_params)
    @keep_in_touch_setting.enable!(on: local_date)

    redirect_to @person, notice: t(".enabled")
  rescue ActiveRecord::RecordInvalid
    redirect_to @person, alert: invalid_setting_message
  rescue ActiveRecord::RecordNotUnique
    redirect_to @person, alert: t(".stale")
  end

  def update
    update_setting { @keep_in_touch_setting.change_cadence!(cadence: setting_params.fetch(:cadence)) }
  end

  def enable
    update_setting { @keep_in_touch_setting.enable!(on: local_date, cadence: setting_params.fetch(:cadence)) }
  end

  def disable
    update_setting { @keep_in_touch_setting.disable! }
  end

  def snooze
    update_setting { @keep_in_touch_setting.snooze!(on: local_date) }
  end

  private

  def set_person
    @person = Current.user.people.friendly.find(params[:person_id])
  end

  def set_keep_in_touch_setting
    @keep_in_touch_setting = @person.keep_in_touch_setting || raise(ActiveRecord::RecordNotFound)
    @keep_in_touch_setting.lock_version = setting_params.fetch(:lock_version)
  end

  def setting_params
    params.expect(keep_in_touch_setting: [ :cadence, :lock_version ])
  end

  def local_date
    Current.user.local_date
  end

  def update_setting
    yield

    redirect_to @person, notice: t(".updated")
  rescue ActiveRecord::RecordInvalid
    redirect_to @person, alert: invalid_setting_message
  rescue ActiveRecord::StaleObjectError
    redirect_to @person, alert: t(".stale")
  end

  def invalid_setting_message
    t(".invalid", reason: @keep_in_touch_setting.errors.full_messages.to_sentence)
  end
end
