require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FriendCrm
  # PostgreSQL integer columns are signed 32-bit values; use this limit for persisted integers so SQLite stays compatible.
  MAX_INT32 = 2_147_483_647

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.available_locales = [ :en, :es ]
    config.i18n.default_locale = :en

    boolean_values = { "true" => true, "false" => false }.freeze

    # Maximum number of matching friends the user sees in search results.
    # FriendSearch applies the cap so broad searches do not load and render an unbounded number of friends.
    config.x.friend_search_max_results = Integer(ENV.fetch("FRIEND_SEARCH_MAX_RESULTS", "50"), 10)
    raise ArgumentError, "FRIEND_SEARCH_MAX_RESULTS must be positive" unless config.x.friend_search_max_results.positive?

    # This is how long the user must pause typing before the search runs.
    # The delay keeps rapid keystrokes from sending a request for every character.
    config.x.friend_search_debounce_milliseconds = Integer(ENV.fetch("FRIEND_SEARCH_DEBOUNCE_MILLISECONDS", "100"), 10)
    raise ArgumentError, "FRIEND_SEARCH_DEBOUNCE_MILLISECONDS must be positive" unless config.x.friend_search_debounce_milliseconds.positive?

    # Optional email confirmation for registrations; see .env.example
    config.x.require_email_confirmation = ENV["REQUIRE_EMAIL_CONFIRMATION"] == "true"

    config.x.default_time_zone = ENV.fetch("DEFAULT_TIME_ZONE", "UTC")
    TZInfo::Timezone.get(config.x.default_time_zone)

    # Fixed day counts make lead times predictable across varying month lengths and leap years.
    config.x.reminder_lead_units = { "days" => 1, "months" => 30, "years" => 365 }.freeze

    config.x.reminder_default_in_app_enabled = boolean_values[ENV.fetch("REMINDER_DEFAULT_IN_APP_ENABLED", "true")]
    raise ArgumentError, "REMINDER_DEFAULT_IN_APP_ENABLED must be true or false" if config.x.reminder_default_in_app_enabled.nil?

    config.x.reminder_default_email_enabled = boolean_values[ENV.fetch("REMINDER_DEFAULT_EMAIL_ENABLED", "true")]
    raise ArgumentError, "REMINDER_DEFAULT_EMAIL_ENABLED must be true or false" if config.x.reminder_default_email_enabled.nil?

    config.x.reminder_default_lead_value = Integer(ENV.fetch("REMINDER_DEFAULT_LEAD_VALUE", "1"), 10)
    if config.x.reminder_default_lead_value.negative? ||
        config.x.reminder_default_lead_value > MAX_INT32
      raise ArgumentError, "REMINDER_DEFAULT_LEAD_VALUE is outside the supported integer range"
    end

    config.x.reminder_default_lead_unit = ENV.fetch("REMINDER_DEFAULT_LEAD_UNIT", "months")
    unless config.x.reminder_lead_units.key?(config.x.reminder_default_lead_unit)
      raise ArgumentError, "REMINDER_DEFAULT_LEAD_UNIT must be one of: #{config.x.reminder_lead_units.keys.join(", ")}"
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
