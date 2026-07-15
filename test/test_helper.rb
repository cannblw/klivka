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
  end
end
