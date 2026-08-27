class BirthdaysController < ApplicationController
  def index
    @today = Date.current
    @selected_month = selected_month
    birthdays = Entry::Birthday
      .where(person_id: Current.user.people.active.select(:id))
      .includes(:person)
      .to_a
      .sort_by { |birthday| [ birthday.entry_date.month, birthday.entry_date.day, birthday.person.name.downcase ] }
    @birthdays_by_month = birthdays.group_by { _1.entry_date.month }
  end

  private

  def selected_month
    month = Integer(params[:month], exception: false)
    month if month&.between?(1, 12)
  end
end
