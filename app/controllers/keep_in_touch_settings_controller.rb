class KeepInTouchSettingsController < ApplicationController
  before_action :set_person
  before_action :set_keep_in_touch_setting, only: %i[ update enable destroy ]

  def create
    return redirect_to @person, alert: t(".already_exists") if @person.keep_in_touch_setting.present?

    @keep_in_touch_setting = @person.build_keep_in_touch_setting(setting_params)
    @keep_in_touch_setting.enable!(on: local_date)

    redirect_to @person, notice: t(".enabled")
  rescue ActiveRecord::RecordInvalid
    redirect_to @person, alert: invalid_setting_message
  rescue ActiveRecord::RecordNotUnique
    redirect_to @person, alert: t(".already_exists")
  end

  def update
    update_setting { @keep_in_touch_setting.change_cadence!(cadence: setting_params.fetch(:cadence)) }
  end

  def enable
    update_setting { @keep_in_touch_setting.enable!(on: local_date, cadence: setting_params.fetch(:cadence)) }
  end

  def disable
    @person.transaction do
      @keep_in_touch_setting = @person.keep_in_touch_setting

      if @keep_in_touch_setting
        @keep_in_touch_setting.disable!
      else
        @keep_in_touch_setting = @person.create_keep_in_touch_setting!(
          cadence: ContactReminder.for(@person).cadence || ContactReminder::DEFAULT_CADENCE
        )
        @person.update!(contact_reminder_snoozed_until: nil)
      end
    end

    redirect_to @person, notice: t(".updated")
  rescue ActiveRecord::RecordInvalid
    redirect_to @person, alert: invalid_setting_message
  rescue ActiveRecord::RecordNotUnique
    redirect_to @person, alert: t(".already_updated")
  end

  def snooze
    snoozed = false

    @person.transaction do
      reminder = ContactReminder.for(@person.reload)
      @keep_in_touch_setting = reminder.setting
      if reminder.due?(on: local_date)
        reminder.snooze!(on: local_date)
        snoozed = true
      end
    end

    if snoozed
      redirect_to snooze_redirect_path, notice: t(".updated")
    else
      redirect_to snooze_redirect_path, alert: t(".unavailable")
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to @person, alert: invalid_setting_message
  end

  def destroy
    @keep_in_touch_setting.transaction do
      @keep_in_touch_setting.destroy!
      @person.update!(contact_reminder_snoozed_until: nil)
    end

    redirect_to @person, notice: t(".updated")
  end

  private

  def set_person
    @person = Current.user.people.active.friendly.find(params[:person_id])
  end

  def set_keep_in_touch_setting
    @keep_in_touch_setting = @person.keep_in_touch_setting || raise(ActiveRecord::RecordNotFound)
  end

  def setting_params
    params.expect(keep_in_touch_setting: [ :cadence ])
  end

  def local_date
    Current.user.local_date
  end

  def snooze_redirect_path
    params[:return_to] == "reminders" ? reminders_path : @person
  end

  def update_setting
    yield

    redirect_to @person, notice: t(".updated")
  rescue ActiveRecord::RecordInvalid
    redirect_to @person, alert: invalid_setting_message
  end

  def invalid_setting_message
    t(".invalid", reason: @keep_in_touch_setting.errors.full_messages.to_sentence)
  end
end
