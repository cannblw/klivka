require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FriendCrm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.available_locales = [ :en, :es ]
    config.i18n.default_locale = :en

    # Maximum number of matching friends the user sees in search results.
    # FriendSearch applies the cap so broad searches do not load and render an unbounded number of friends.
    config.x.friend_search_max_results = Integer(ENV.fetch("FRIEND_SEARCH_MAX_RESULTS", "50"), 10)
    raise ArgumentError, "FRIEND_SEARCH_MAX_RESULTS must be positive" unless config.x.friend_search_max_results.positive?

    # Optional email confirmation for registrations; see .env.example
    config.x.require_email_confirmation = ENV["REQUIRE_EMAIL_CONFIRMATION"] == "true"

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
