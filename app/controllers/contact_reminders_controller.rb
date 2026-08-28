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
      reminder.override!(cadence: selection, on: Current.user.local_date)
    end

    redirect_to contact_reminders_path, notice: t(".updated", name: person.name)
  rescue ActiveRecord::RecordInvalid => error
    redirect_to contact_reminders_path, alert: t(".invalid", reason: error.record.errors.full_messages.to_sentence)
  end

  private

  def prepare_index
    @people = Current.user.people.active.includes(:user, :keep_in_touch_setting).to_a
      .sort_by { |person| [ PersonNameNormalizer.call(person.name), person.id ] }
  end

  def contact_reminder_params
    params.expect(contact_reminder: [ :selection ])
  end
end
