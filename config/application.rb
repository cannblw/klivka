require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FriendCrm
  # PostgreSQL integer columns are signed 32-bit values; use this limit for persisted integers so SQLite stays compatible.
  MAX_INT32 = 2_147_483_647
  # SQLite does not enforce declared string lengths; use this limit with explicit constraints so PostgreSQL and SQLite stay compatible.
  STRING_MAX_LENGTH = 255

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

    config.x.vcard_import_max_file_size_bytes = Integer(ENV.fetch("VCARD_IMPORT_MAX_FILE_SIZE_BYTES", 5.megabytes.to_s), 10)
    unless config.x.vcard_import_max_file_size_bytes.positive?
      raise ArgumentError, "VCARD_IMPORT_MAX_FILE_SIZE_BYTES must be positive"
    end

    config.x.vcard_import_max_cards = Integer(ENV.fetch("VCARD_IMPORT_MAX_CARDS", "5000"), 10)
    raise ArgumentError, "VCARD_IMPORT_MAX_CARDS must be positive" unless config.x.vcard_import_max_cards.positive?

    config.x.vcard_import_preview_lifetime = Integer(ENV.fetch("VCARD_IMPORT_PREVIEW_LIFETIME_HOURS", "1"), 10).hours
    raise ArgumentError, "VCARD_IMPORT_PREVIEW_LIFETIME_HOURS must be positive" unless config.x.vcard_import_preview_lifetime.positive?

    config.x.vcard_import_upload_rate_limit = Integer(ENV.fetch("VCARD_IMPORT_UPLOAD_RATE_LIMIT", "10"), 10)
    raise ArgumentError, "VCARD_IMPORT_UPLOAD_RATE_LIMIT must be positive" unless config.x.vcard_import_upload_rate_limit.positive?

    config.x.vcard_import_upload_rate_window = Integer(ENV.fetch("VCARD_IMPORT_UPLOAD_RATE_WINDOW_MINUTES", "60"), 10).minutes
    unless config.x.vcard_import_upload_rate_window.positive?
      raise ArgumentError, "VCARD_IMPORT_UPLOAD_RATE_WINDOW_MINUTES must be positive"
    end

    # Optional email confirmation for registrations; see .env.example
    config.x.require_email_confirmation = ENV["REQUIRE_EMAIL_CONFIRMATION"] == "true"

    config.x.default_time_zone = ENV.fetch("DEFAULT_TIME_ZONE", "UTC")
    TZInfo::Timezone.get(config.x.default_time_zone)

    config.x.development_seed_email_address = ENV.fetch("DEVELOPMENT_SEED_EMAIL_ADDRESS", "admin@example.com").strip.downcase
    unless config.x.development_seed_email_address.match?(URI::MailTo::EMAIL_REGEXP)
      raise ArgumentError, "DEVELOPMENT_SEED_EMAIL_ADDRESS must be a valid email address"
    end

    config.x.development_seed_password = ENV.fetch("DEVELOPMENT_SEED_PASSWORD", "admin")
    raise ArgumentError, "DEVELOPMENT_SEED_PASSWORD cannot be blank" if config.x.development_seed_password.blank?

    # Fixed day counts make lead times predictable across varying month lengths and leap years.
    config.x.reminder_lead_units = { "days" => 1, "months" => 30, "years" => 365 }.freeze

    config.x.reminder_default_in_app_enabled = boolean_values[ENV.fetch("REMINDER_DEFAULT_IN_APP_ENABLED", "true")]
    raise ArgumentError, "REMINDER_DEFAULT_IN_APP_ENABLED must be true or false" if config.x.reminder_default_in_app_enabled.nil?

    config.x.reminder_default_email_enabled = boolean_values[ENV.fetch("REMINDER_DEFAULT_EMAIL_ENABLED", "true")]
    raise ArgumentError, "REMINDER_DEFAULT_EMAIL_ENABLED must be true or false" if config.x.reminder_default_email_enabled.nil?

    config.x.birthday_reminder_default_enabled = boolean_values[ENV.fetch("BIRTHDAY_REMINDER_DEFAULT_ENABLED", "true")]
    if config.x.birthday_reminder_default_enabled.nil?
      raise ArgumentError, "BIRTHDAY_REMINDER_DEFAULT_ENABLED must be true or false"
    end

    config.x.reminder_default_lead_value = Integer(ENV.fetch("REMINDER_DEFAULT_LEAD_VALUE", "1"), 10)
    if config.x.reminder_default_lead_value.negative? ||
        config.x.reminder_default_lead_value > MAX_INT32
      raise ArgumentError, "REMINDER_DEFAULT_LEAD_VALUE is outside the supported integer range"
    end

    config.x.reminder_default_lead_unit = ENV.fetch("REMINDER_DEFAULT_LEAD_UNIT", "months")
    unless config.x.reminder_lead_units.key?(config.x.reminder_default_lead_unit)
      raise ArgumentError, "REMINDER_DEFAULT_LEAD_UNIT must be one of: #{config.x.reminder_lead_units.keys.join(", ")}"
    end

    config.x.reminder_scan_batch_size = Integer(ENV.fetch("REMINDER_SCAN_BATCH_SIZE", "100"), 10)
    raise ArgumentError, "REMINDER_SCAN_BATCH_SIZE must be positive" unless config.x.reminder_scan_batch_size.positive?

    config.x.reminder_account_batch_size = Integer(ENV.fetch("REMINDER_ACCOUNT_BATCH_SIZE", "500"), 10)
    raise ArgumentError, "REMINDER_ACCOUNT_BATCH_SIZE must be positive" unless config.x.reminder_account_batch_size.positive?

    config.x.reminder_job_threads = Integer(ENV.fetch("REMINDER_JOB_THREADS", "5"), 10)
    raise ArgumentError, "REMINDER_JOB_THREADS must be positive" unless config.x.reminder_job_threads.positive?

    config.x.reminder_dispatch_interval = Integer(ENV.fetch("REMINDER_DISPATCH_INTERVAL_MINUTES", "60"), 10).minutes
    raise ArgumentError, "REMINDER_DISPATCH_INTERVAL_MINUTES must be positive" unless config.x.reminder_dispatch_interval.positive?

    config.x.application_url = ENV.fetch("APPLICATION_URL", "http://localhost:3000").strip.chomp("/")
    application_uri = URI.parse(config.x.application_url)
    unless application_uri.is_a?(URI::HTTP) && application_uri.host.present? && application_uri.userinfo.nil? &&
        application_uri.query.nil? && application_uri.fragment.nil?
      raise ArgumentError, "APPLICATION_URL must be an HTTP(S) URL without credentials, query, or fragment"
    end

    config.x.mail_from = ENV.fetch("MAIL_FROM", "Klivka <from@example.com>").strip
    mail_from_address = Mail::Address.new(config.x.mail_from).address
    unless mail_from_address.match?(URI::MailTo::EMAIL_REGEXP)
      raise ArgumentError, "MAIL_FROM must contain a valid email address"
    end

    config.x.reminder_mail_transport = ENV.fetch("REMINDER_MAIL_TRANSPORT", "rails").strip.downcase

    config.x.reminder_delivery_retry_attempts = Integer(ENV.fetch("REMINDER_DELIVERY_RETRY_ATTEMPTS", "5"), 10)
    raise ArgumentError, "REMINDER_DELIVERY_RETRY_ATTEMPTS must be positive" unless config.x.reminder_delivery_retry_attempts.positive?

    config.x.reminder_delivery_claim_timeout = Integer(ENV.fetch("REMINDER_DELIVERY_CLAIM_TIMEOUT_MINUTES", "30"), 10).minutes
    raise ArgumentError, "REMINDER_DELIVERY_CLAIM_TIMEOUT_MINUTES must be positive" unless config.x.reminder_delivery_claim_timeout.positive?

    config.x.resend_api_key = ENV["RESEND_API_KEY"].presence || Rails.application.credentials.dig(:resend, :api_key)
    if config.x.reminder_mail_transport == "resend" && config.x.resend_api_key.blank?
      raise ArgumentError, "RESEND_API_KEY or credentials.resend.api_key is required for the Resend reminder transport"
    end

    config.x.job_processes = Integer(ENV.fetch("JOB_CONCURRENCY", "1"), 10)
    raise ArgumentError, "JOB_CONCURRENCY must be positive" unless config.x.job_processes.positive?

    # Solid Queue needs one connection per worker thread plus separate polling and heartbeat connections.
    config.x.queue_database_pool = [ 3, config.x.reminder_job_threads ].max + 2

    config.x.demo_mode = boolean_values[ENV.fetch("DEMO_MODE", "false")]
    raise ArgumentError, "DEMO_MODE must be true or false" if config.x.demo_mode.nil?

    config.x.demo_user_email_address = ENV.fetch("DEMO_USER_EMAIL_ADDRESS", "demo@klivka.com").strip.downcase
    unless config.x.demo_user_email_address.match?(URI::MailTo::EMAIL_REGEXP)
      raise ArgumentError, "DEMO_USER_EMAIL_ADDRESS must be a valid email address"
    end

    config.x.demo_reset_minimum_age = Integer(ENV.fetch("DEMO_RESET_MINIMUM_AGE_HOURS", "24"), 10).hours
    raise ArgumentError, "DEMO_RESET_MINIMUM_AGE_HOURS must be positive" unless config.x.demo_reset_minimum_age.positive?

    config.x.demo_reset_idle_period = Integer(ENV.fetch("DEMO_RESET_IDLE_MINUTES", "30"), 10).minutes
    raise ArgumentError, "DEMO_RESET_IDLE_MINUTES must be positive" unless config.x.demo_reset_idle_period.positive?

    config.x.demo_reset_maximum_age = Integer(ENV.fetch("DEMO_RESET_MAXIMUM_AGE_HOURS", "72"), 10).hours
    raise ArgumentError, "DEMO_RESET_MAXIMUM_AGE_HOURS must be positive" unless config.x.demo_reset_maximum_age.positive?
    unless config.x.demo_reset_maximum_age > config.x.demo_reset_minimum_age
      raise ArgumentError, "DEMO_RESET_MAXIMUM_AGE_HOURS must exceed DEMO_RESET_MINIMUM_AGE_HOURS"
    end

    config.x.demo_reset_check_interval = Integer(ENV.fetch("DEMO_RESET_CHECK_INTERVAL_MINUTES", "15"), 10).minutes
    unless config.x.demo_reset_check_interval.positive?
      raise ArgumentError, "DEMO_RESET_CHECK_INTERVAL_MINUTES must be positive"
    end

    config.x.demo_mutation_rate_limit = Integer(ENV.fetch("DEMO_MUTATION_RATE_LIMIT", "120"), 10)
    raise ArgumentError, "DEMO_MUTATION_RATE_LIMIT must be positive" unless config.x.demo_mutation_rate_limit.positive?

    config.x.demo_mutation_rate_window = Integer(ENV.fetch("DEMO_MUTATION_RATE_WINDOW_MINUTES", "10"), 10).minutes
    raise ArgumentError, "DEMO_MUTATION_RATE_WINDOW_MINUTES must be positive" unless config.x.demo_mutation_rate_window.positive?

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
