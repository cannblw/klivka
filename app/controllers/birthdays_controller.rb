class BirthdaysController < ApplicationController
  def index
    @birthdays = Entry::Birthday
      .for_month
      .where(friend_id: Current.user.friends.select(:id))
      .includes(:friend)
      .order(:entry_date)
  end
end
