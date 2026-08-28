require "test_helper"

# == Schema Information
#
# Table name: contact_reminder_digests
#
#  id           :integer          not null, primary key
#  attempts     :integer          default(0), not null
#  canceled_at  :datetime
#  claim_token  :string
#  claimed_at   :datetime
#  delivered_at :datetime
#  delivery_on  :date             not null
#  failed_at    :datetime
#  status       :string           default("pending"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_contact_reminder_digests_on_status_and_delivery_on   (status,delivery_on)
#  index_contact_reminder_digests_on_user_id                  (user_id)
#  index_contact_reminder_digests_on_user_id_and_delivery_on  (user_id,delivery_on) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class ContactReminderDigestTest < ActiveSupport::TestCase
  test "allows one digest for an account on each local delivery date" do
    digest = ContactReminderDigest.create!(user: users(:one), delivery_on: Date.new(2026, 8, 28))
    duplicate = ContactReminderDigest.new(user: users(:one), delivery_on: digest.delivery_on)

    assert_not_predicate duplicate, :valid?
    assert duplicate.errors.of_kind?(:delivery_on, :taken)
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }

    assert_predicate ContactReminderDigest.new(user: users(:two), delivery_on: digest.delivery_on), :valid?
  end

  test "requires supported lifecycle values at model and database boundaries" do
    digest = ContactReminderDigest.create!(user: users(:one), delivery_on: Date.new(2026, 8, 28))

    digest.status = "queued"
    digest.attempts = -1
    assert_not_predicate digest, :valid?
    assert digest.errors.of_kind?(:status, :inclusion)
    assert digest.errors.of_kind?(:attempts, :greater_than_or_equal_to)

    assert_raises(ActiveRecord::StatementInvalid) { digest.update_column(:status, "queued") }
    assert_raises(ActiveRecord::StatementInvalid) { digest.update_column(:attempts, -1) }
  end

  test "requires complete claim metadata at model and database boundaries" do
    digest = ContactReminderDigest.create!(user: users(:one), delivery_on: Date.new(2026, 8, 28))

    digest.claimed_at = Time.utc(2026, 8, 28, 8)
    assert_not_predicate digest, :valid?
    assert digest.errors.of_kind?(:claim_token, :blank)

    digest.claimed_at = nil
    digest.claim_token = "claim-token"
    assert_not_predicate digest, :valid?
    assert digest.errors.of_kind?(:claimed_at, :blank)

    assert_raises(ActiveRecord::StatementInvalid) do
      digest.update_columns(claimed_at: Time.utc(2026, 8, 28, 8), claim_token: nil)
    end
  end

  test "deleting an account removes its digest history" do
    user = User.create!(email_address: "digest-owner@example.com", password: "password", time_zone: "UTC")
    ContactReminderDigest.create!(user:, delivery_on: Date.new(2026, 8, 28))

    assert_difference [ "User.count", "ContactReminderDigest.count" ], -1 do
      user.destroy!
    end
  end
end
