class RemindersController < ApplicationController
  def index
    @due_contact_reminders = DueContactRemindersQuery.call(user: Current.user)
    @interactions_by_person_id = {}
  end
end
