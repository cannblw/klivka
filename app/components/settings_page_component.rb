class SettingsPageComponent < ViewComponent::Base
  DESTINATIONS = %i[ account preferences reminders contact_methods ].freeze

  def initialize(active:)
    raise ArgumentError, "unknown settings destination: #{active}" unless DESTINATIONS.include?(active)

    @active = active
  end

  private

  attr_reader :active

  def destinations
    DESTINATIONS.map do |destination|
      [ destination, destination_path(destination) ]
    end
  end

  def destination_path(destination)
    case destination
    when :account then helpers.settings_path
    when :preferences then helpers.settings_preferences_path
    when :reminders then helpers.settings_reminders_path
    when :contact_methods then helpers.contact_methods_path
    end
  end

  def link_classes(destination)
    base = "block rounded-lg px-3 py-2 text-sm font-medium transition"
    current = "bg-brand-surface text-brand-link dark:bg-brand-dark-surface/30 dark:text-brand-on-dark"
    other = "text-stone-600 hover:bg-stone-100 hover:text-stone-900 dark:text-stone-300 dark:hover:bg-stone-700 dark:hover:text-stone-100"

    "#{base} #{destination == active ? current : other}"
  end
end
