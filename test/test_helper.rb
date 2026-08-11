ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def with_email_confirmation_required
      original = Rails.application.config.x.require_email_confirmation
      Rails.application.config.x.require_email_confirmation = true
      yield
    ensure
      Rails.application.config.x.require_email_confirmation = original
    end

    def with_demo_mode(user: nil)
      configuration = Rails.application.config.x
      original_mode = configuration.demo_mode
      original_email_address = configuration.demo_user_email_address
      user ||= User.create!(email_address: "demo-mode@example.com", password: "a-safe-password")
      configuration.demo_mode = true
      configuration.demo_user_email_address = user.email_address
      Rails.cache.clear

      yield user
    ensure
      Rails.cache.clear
      configuration.demo_mode = original_mode
      configuration.demo_user_email_address = original_email_address
    end
  end
end
