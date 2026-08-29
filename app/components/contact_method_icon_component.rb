class ContactMethodIconComponent < ViewComponent::Base
  SIMPLE_ICONS_VERSION = "16.29.0"
  SIMPLE_ICONS_BASE_URL = "https://cdn.jsdelivr.net/npm/simple-icons@#{SIMPLE_ICONS_VERSION}/icons"

  def initialize(icon_library:, icon_name:, size: 20, **options)
    @icon_library = icon_library
    @icon_name = icon_name
    @size = size
    @options = options
  end

  def render?
    icon_library.present? && icon_name.present? && ContactMethodIcons.valid?(icon_library, icon_name)
  end

  private

  attr_reader :icon_library, :icon_name, :size, :options

  def material_icon?
    icon_library == "material_icons"
  end

  def simple_icon_url
    "#{SIMPLE_ICONS_BASE_URL}/#{icon_name}.svg"
  end
end
