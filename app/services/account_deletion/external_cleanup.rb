module AccountDeletion
  class ExternalCleanup
    def self.call(account_id:)
      Rails.application.config.x.account_deletion_cleanup_handlers.each do |handler|
        handler.call(account_id:)
      end
    end
  end
end
