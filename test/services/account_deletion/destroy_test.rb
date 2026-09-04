require "test_helper"

class AccountDeletion::DestroyTest < ActiveJob::TestCase
  test "deletes the account and all of its owned data in one transaction" do
    user = users(:one)
    account_id = user.id
    person_ids = user.people.ids
    entry_ids = Entry.where(person_id: person_ids).ids
    interaction_ids = Interaction.where(person_id: person_ids).ids
    user.sessions.create!(user_agent: "another browser")

    assert_enqueued_with(job: AccountDeletion::ExternalCleanupJob, args: [ account_id ]) do
      assert AccountDeletion::Destroy.call(user:)
    end

    assert_not User.exists?(account_id)
    assert_empty Session.where(user_id: account_id)
    assert_empty Category.where(user_id: account_id)
    assert_empty ContactMethod.where(user_id: account_id)
    assert_empty Person.where(id: person_ids)
    assert_empty Entry.where(id: entry_ids)
    assert_empty Interaction.where(id: interaction_ids)
    assert_empty ReminderDelivery.where(user_id: account_id)
    assert_empty ContactReminderDigest.where(user_id: account_id)
    assert_empty VcardImport.where(user_id: account_id)
    assert User.exists?(users(:two).id)
  end

  test "rolls database deletion back when the transaction fails" do
    user = users(:one)
    account_id = user.id
    person_ids = user.people.ids

    assert_raises RuntimeError do
      AccountOperationLock.with(account_id) do |account|
        account.destroy!
        raise "simulated transaction failure"
      end
    end

    assert User.exists?(account_id)
    assert_equal person_ids.sort, Person.where(user_id: account_id).ids.sort
  end

  test "does not enqueue cleanup when the account is already gone" do
    user = User.create!(email_address: "already-deleted@example.com", password: "password", time_zone: "UTC")
    user.destroy!

    assert_no_enqueued_jobs do
      assert_not AccountDeletion::Destroy.call(user:)
    end
  end
end
