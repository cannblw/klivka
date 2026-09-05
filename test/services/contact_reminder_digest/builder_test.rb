require "test_helper"

class ContactReminderDigest::BuilderTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @delivery_on = Date.new(2026, 8, 28)
  end

  test "creates one daily digest containing every eligible contact email delivery" do
    first = create_delivery(people(:ada), reminder_on: @delivery_on - 1.day)
    second = create_delivery(people(:grace), reminder_on: @delivery_on)

    digest = ContactReminderDigest::Builder.call(user: @user, at: local_time(8))

    assert_equal @delivery_on, digest.delivery_on
    assert_equal [ first.id, second.id ].sort, digest.reminder_delivery_ids.sort
    assert_equal ContactReminderDigest::PENDING_STATUS, digest.status
  end

  test "waits until the configured hour in the account time zone" do
    create_delivery(people(:ada), reminder_on: @delivery_on)

    assert_no_difference "ContactReminderDigest.count" do
      assert_nil ContactReminderDigest::Builder.call(user: @user, at: local_time(7, 59))
    end

    assert_difference "ContactReminderDigest.count", 1 do
      ContactReminderDigest::Builder.call(user: @user, at: local_time(8))
    end
  end

  test "does not create an empty digest" do
    assert_no_difference "ContactReminderDigest.count" do
      assert_nil ContactReminderDigest::Builder.call(user: @user, at: local_time(8))
    end
  end

  test "includes only due pending contact email work belonging to the account" do
    eligible = create_delivery(people(:ada), reminder_on: @delivery_on)
    create_delivery(people(:grace), reminder_on: @delivery_on + 1.day)
    create_delivery(people(:grace), reminder_on: @delivery_on - 1.day, channel: "in_app")
    birthday = entries(:ada_birthday)
    create_delivery(birthday, reminder_on: @delivery_on - 1.day)
    other_person = people(:bob)
    other_person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: @delivery_on - 1.week)
    create_delivery(other_person, reminder_on: @delivery_on, user: users(:two))

    digest = ContactReminderDigest::Builder.call(user: @user, at: local_time(8))

    assert_equal [ eligible ], digest.reminder_deliveries.to_a
  end

  test "freezes membership and leaves later work for the next local day" do
    first = create_delivery(people(:ada), reminder_on: @delivery_on)
    digest = ContactReminderDigest::Builder.call(user: @user, at: local_time(8))
    late = create_delivery(people(:grace), reminder_on: @delivery_on)

    assert_no_difference "ContactReminderDigest.count" do
      assert_equal digest, ContactReminderDigest::Builder.call(user: @user, at: local_time(12))
    end
    assert_equal [ first ], digest.reminder_deliveries.reload.to_a
    assert_nil late.reload.contact_reminder_digest

    next_digest = ContactReminderDigest::Builder.call(user: @user, at: local_time(8, date: @delivery_on.next_day))

    assert_equal @delivery_on.next_day, next_digest.delivery_on
    assert_equal [ late ], next_digest.reminder_deliveries.to_a
  end

  test "includes failed individual contact work in the next digest" do
    delivery = create_delivery(people(:ada), reminder_on: @delivery_on)
    delivery.update!(status: ReminderDelivery::FAILED_STATUS, failed_at: local_time(7))

    digest = ContactReminderDigest::Builder.call(user: @user, at: local_time(8))

    assert_equal [ delivery ], digest.reminder_deliveries.to_a
  end

  private

  def create_delivery(source, reminder_on:, user: @user, channel: "email")
    ReminderDelivery.create!(
      user:, source:, channel:, reminder_on:, occurrence_on: reminder_on
    )
  end

  def local_time(hour, minute = 0, date: @delivery_on)
    Time.use_zone(@user.time_zone) { Time.zone.local(date.year, date.month, date.day, hour, minute).utc }
  end
end
