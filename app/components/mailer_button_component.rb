class MailerButtonComponent < ViewComponent::Base
  def initialize(label:, url:)
    @label = label
    @url = url
  end

  private

  attr_reader :label, :url
end
