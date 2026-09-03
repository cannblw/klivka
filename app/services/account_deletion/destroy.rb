module AccountDeletion
  class Destroy
    def self.call(user:)
      account_id = user.id
      deleted = AccountOperationLock.with(account_id) do |account|
        account.destroy!
        true
      end
      return false unless deleted

      ExternalCleanupJob.perform_later(account_id)
      true
    end
  end
end
