require "test_helper"

class ApplicationConfigurationTest < ActiveSupport::TestCase
  test "application uses the Klivka namespace" do
    assert_equal Klivka::Application, Rails.application.class
  end

  test "defines safe demo defaults" do
    configuration = Rails.application.config.x

    assert_not configuration.demo_mode
    assert_equal "demo@klivka.com", configuration.demo_user_email_address
    assert_equal 24.hours, configuration.demo_reset_minimum_age
    assert_equal 30.minutes, configuration.demo_reset_idle_period
    assert_equal 72.hours, configuration.demo_reset_maximum_age
    assert_equal 15.minutes, configuration.demo_reset_check_interval
    assert_equal 120, configuration.demo_mutation_rate_limit
    assert_equal 10.minutes, configuration.demo_mutation_rate_window
    assert_equal 100, configuration.reminder_scan_batch_size
    assert_equal 500, configuration.reminder_account_batch_size
    assert_equal 5, configuration.reminder_job_threads
    assert_equal 60.minutes, configuration.reminder_dispatch_interval
    assert_equal 8, configuration.contact_reminder_digest_hour
    assert_equal 1, configuration.job_processes
    assert_equal 7, configuration.queue_database_pool
    assert_equal 5.megabytes, configuration.vcard_import_max_file_size_bytes
    assert_equal 5_000, configuration.vcard_import_max_cards
    assert_equal 1.hour, configuration.vcard_import_preview_lifetime
    assert_equal 10, configuration.vcard_import_upload_rate_limit
    assert_equal 60.minutes, configuration.vcard_import_upload_rate_window
  end

  test "application defines safe reminder email delivery defaults" do
    configuration = Rails.application.config.x

    assert_equal "http://localhost:3000", configuration.application_url
    assert_equal "Klivka <from@example.com>", configuration.mail_from
    assert_equal "rails", configuration.reminder_mail_transport
    assert_equal 5, configuration.reminder_delivery_retry_attempts
    assert_equal 30.minutes, configuration.reminder_delivery_claim_timeout
    assert_nil configuration.resend_api_key
  end
end
