class EntryFormComponent < ViewComponent::Base
  def initialize(entry:, friend:)
    @entry = entry
    @friend = friend
  end

  private

  attr_reader :entry, :friend
end
