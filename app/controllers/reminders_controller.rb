class RemindersController < ApplicationController
  def index
    @due_contact_reminders = DueContactRemindersQuery.call(user: Current.user)
  end
end
