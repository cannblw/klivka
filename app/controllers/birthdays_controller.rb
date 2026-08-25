class BirthdaysController < ApplicationController
  def index
    @today = Date.current
    @selected_month = selected_month
    birthdays = Entry::Birthday
      .where(friend_id: Current.user.friends.select(:id))
      .includes(:friend)
      .to_a
      .sort_by { |birthday| [ birthday.entry_date.month, birthday.entry_date.day, birthday.friend.name.downcase ] }
    @birthdays_by_month = birthdays.group_by { _1.entry_date.month }
  end

  private

  def selected_month
    month = Integer(params[:month], exception: false)
    month if month&.between?(1, 12)
  end
end
