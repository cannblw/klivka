class BackLinkComponent < ViewComponent::Base
  def initialize(fallback_path:)
    @fallback_path = fallback_path
  end

  private

  attr_reader :fallback_path
end
