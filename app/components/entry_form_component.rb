class EntryFormComponent < ViewComponent::Base
  def initialize(entry:, friend:)
    @entry = entry
    @friend = friend
  end

  private

  attr_reader :entry, :friend

  def entry_supports_reminders?
    EntryReminder.eligible_entry?(entry)
  end
end
