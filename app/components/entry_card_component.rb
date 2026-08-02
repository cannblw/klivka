class EntryCardComponent < ViewComponent::Base
  def initialize(entry:, friend:)
    @entry = entry
    @friend = friend
  end

  private

  attr_reader :entry, :friend

  def kind_key
    entry.type.demodulize.underscore
  end
end
