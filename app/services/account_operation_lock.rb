class AccountOperationLock
  def self.with(account_id, &block)
    User.transaction do
      account = User.lock.find_by(id: account_id)
      block.call(account) if account
    end
  end
end
