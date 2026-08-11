require "test_helper"
require_relative "../../db/seeds/sample_data"
require_relative "../../db/seeds/demo"

class DemoSeedDataTest < ActiveSupport::TestCase
  test "creates the shared demo account with sample data" do
    user = DemoSeedData.call(email_address: "demo-seed@example.com")

    assert_predicate user, :persisted?
    assert_equal "demo-seed@example.com", user.email_address
    assert user.password_digest.present?
    assert_equal SampleSeedData::FRIEND_COUNT, user.friends.count
  end

  test "does not replace existing demo data during a subsequent seed" do
    user = DemoSeedData.call(email_address: "existing-demo-seed@example.com")
    user.friends.create!(name: "Visitor addition")

    reseeded_user = DemoSeedData.call(email_address: user.email_address)

    assert_equal user, reseeded_user
    assert_equal SampleSeedData::FRIEND_COUNT + 1, reseeded_user.friends.count
    assert reseeded_user.friends.exists?(name: "Visitor addition")
  end

  test "restores sample data when the existing demo account is empty" do
    user = User.create!(email_address: "empty-demo-seed@example.com", password: "a-safe-password")

    seeded_user = DemoSeedData.call(email_address: user.email_address)

    assert_equal user, seeded_user
    assert_equal SampleSeedData::FRIEND_COUNT, seeded_user.friends.count
  end

  test "does not leave a new demo account behind when sample data cannot be created" do
    failing_seed_data = Class.new do
      def self.call(user:)
        raise ActiveRecord::RecordInvalid, user
      end
    end

    stub_const(Object, :SampleSeedData, failing_seed_data) do
      assert_raises(ActiveRecord::RecordInvalid) do
        DemoSeedData.call(email_address: "failed-demo-seed@example.com")
      end
    end

    assert_not User.exists?(email_address: "failed-demo-seed@example.com")
  end
end
