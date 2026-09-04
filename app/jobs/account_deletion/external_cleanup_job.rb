module AccountDeletion
  class ExternalCleanupJob < ApplicationJob
    queue_as :background

    retry_on StandardError,
      attempts: Rails.application.config.x.account_deletion_cleanup_retry_attempts,
      wait: :polynomially_longer

    def perform(account_id)
      ExternalCleanup.call(account_id:)
    end
  end
end
