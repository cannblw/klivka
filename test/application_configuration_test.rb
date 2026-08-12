require "test_helper"

class ApplicationConfigurationTest < ActiveSupport::TestCase
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
  end
end
