class ContactRemindersController < ApplicationController
  def index
    prepare_index
  end

  def update
    person = Current.user.people.active.includes(:user, :keep_in_touch_setting).friendly.find(params[:person_id])
    reminder = ContactReminder.for(person)
    selection = contact_reminder_params.fetch(:selection)

    case selection
    when ContactReminder::DEFAULT_SELECTION
      reminder.use_default!
    when ContactReminder::OFF_SELECTION
      reminder.opt_out!
    else
      unless reminder.overridden? && reminder.cadence == selection && !schedule_changed?
        reminder.override!(
          cadence: selection,
          on: Current.user.local_date,
          first_reminder_on: resolved_first_reminder_on(selection)
        )
      end
    end

    redirect_to contact_reminders_path, notice: t(".updated", name: person.name)
  rescue ActiveRecord::RecordInvalid => error
    redirect_to contact_reminders_path, alert: t(".invalid", reason: error.record.errors.full_messages.to_sentence)
  rescue ContactReminder::InvalidSchedule
    redirect_to contact_reminders_path, alert: t(".invalid", reason: t("contact_reminder.schedule.invalid"))
  end

  private

  def prepare_index
    @people = Current.user.people.active.includes(:user, :keep_in_touch_setting).to_a
      .sort_by { |person| [ PersonNameNormalizer.call(person.name), person.id ] }
  end

  def contact_reminder_params
    params.expect(contact_reminder: [
      :selection,
      :contact_reminder_schedule_changed,
      :first_reminder_weekday,
      :first_reminder_date,
      :first_reminder_day,
      :first_reminder_month
    ])
  end

  def schedule_changed?
    contact_reminder_params[:contact_reminder_schedule_changed] == "1"
  end

  def resolved_first_reminder_on(cadence)
    return unless ContactReminder::CADENCES.include?(cadence)

    schedule = contact_reminder_params.slice(
      :first_reminder_weekday, :first_reminder_date, :first_reminder_day, :first_reminder_month
    )
    return ContactReminder.default_first_reminder_on(cadence:, on: Current.user.local_date) if schedule.values.all?(&:blank?)

    ContactReminder.resolve_first_reminder_on(cadence:, on: Current.user.local_date, selection: schedule)
  end
end
