require "test_helper"

class DemoSeederTest < ActiveSupport::TestCase
  test "creates the shared demo account with sample data" do
    user = DemoSeeder.call(email_address: "demo-seed@example.com")

    assert_predicate user, :persisted?
    assert_equal "demo-seed@example.com", user.email_address
    assert user.password_digest.present?
    assert_equal DemoPersonaSeeder::PERSON_COUNT, user.people.count
    assert_equal DemoState::SHARED_KEY, DemoState.current.key
  end

  test "does not replace existing demo data during a subsequent seed" do
    user = DemoSeeder.call(email_address: "existing-demo-seed@example.com")
    user.people.create!(name: "Visitor addition")

    reseeded_user = DemoSeeder.call(email_address: user.email_address)

    assert_equal user, reseeded_user
    assert_equal DemoPersonaSeeder::PERSON_COUNT + 1, reseeded_user.people.count
    assert reseeded_user.people.exists?(name: "Visitor addition")
  end

  test "restores sample data when the existing demo account is empty" do
    user = User.create!(email_address: "empty-demo-seed@example.com", password: "a-safe-password")

    seeded_user = DemoSeeder.call(email_address: user.email_address)

    assert_equal user, seeded_user
    assert_equal DemoPersonaSeeder::PERSON_COUNT, seeded_user.people.count
  end

  test "does not leave a new demo account behind when sample data cannot be created" do
    failing_seed_data = Class.new do
      def self.call(user:)
        raise ActiveRecord::RecordInvalid, user
      end
    end

    stub_const(Object, :DemoPersonaSeeder, failing_seed_data) do
      assert_raises(ActiveRecord::RecordInvalid) do
        DemoSeeder.call(email_address: "failed-demo-seed@example.com")
      end
    end

    assert_not User.exists?(email_address: "failed-demo-seed@example.com")
  end
end
