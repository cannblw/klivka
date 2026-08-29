class RemindersController < ApplicationController
  def index
    @in_app_reminders = InAppRemindersQuery.call(user: Current.user)
    @interactions_by_person_id = {}
  end
end
