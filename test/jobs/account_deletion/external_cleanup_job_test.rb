require "test_helper"

class AccountDeletion::ExternalCleanupJobTest < ActiveJob::TestCase
  setup do
    @configuration = Rails.application.config.x
    @original_handlers = @configuration.account_deletion_cleanup_handlers
  end

  teardown do
    @configuration.account_deletion_cleanup_handlers = @original_handlers
  end

  test "passes only the deleted account identifier to cleanup handlers" do
    cleaned_accounts = []
    handler = ->(account_id:) { cleaned_accounts << account_id }
    @configuration.account_deletion_cleanup_handlers = [ handler ]

    AccountDeletion::ExternalCleanupJob.perform_now(123)

    assert_equal [ 123 ], cleaned_accounts
    assert_equal "background", AccountDeletion::ExternalCleanupJob.queue_name
  end

  test "retries failed external cleanup" do
    handler = ->(account_id:) { raise "cleanup unavailable for account #{account_id}" }
    @configuration.account_deletion_cleanup_handlers = [ handler ]

    assert_enqueued_with(job: AccountDeletion::ExternalCleanupJob, args: [ 123 ]) do
      AccountDeletion::ExternalCleanupJob.perform_now(123)
    end
  end
end
