require "test_helper"

class ReminderDeliveryDispatchJobTest < ActiveJob::TestCase
  test "finishes safely when the account was deleted after dispatch" do
    assert_no_enqueued_jobs do
      ReminderDeliveryDispatchJob.perform_now(-1, at: Time.utc(2026, 8, 8, 12))
    end
  end

  test "dispatches one contact digest and keeps date reminder emails individual" do
    user = users(:one)
    contact_delivery = create_contact_delivery(people(:ada), user:, reminder_on: Date.new(2026, 8, 8))
    birthday_delivery = ReminderDelivery.create!(
      user:, source: entries(:ada_birthday), channel: "email",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 9, 8)
    )

    assert_enqueued_jobs 2 do
      ReminderDeliveryDispatchJob.perform_now(user.id, at: local_time(user, Date.new(2026, 8, 8), 8))
    end

    digest = user.contact_reminder_digests.find_by!(delivery_on: Date.new(2026, 8, 8))
    assert_equal digest, contact_delivery.reload.contact_reminder_digest
    assert_enqueued_with(job: ContactReminderDigestEmailJob, args: [ digest.id ])
    assert_enqueued_with(job: ReminderDeliveryEmailJob, args: [ birthday_delivery.id ])
  end

  test "waits until the local digest hour without dispatching contacts individually" do
    user = users(:one)
    delivery = create_contact_delivery(people(:ada), user:, reminder_on: Date.new(2026, 8, 8))

    assert_no_enqueued_jobs do
      ReminderDeliveryDispatchJob.perform_now(user.id, at: local_time(user, Date.new(2026, 8, 8), 7, 59))
    end

    assert_nil delivery.reload.contact_reminder_digest
    assert_empty user.contact_reminder_digests
  end

  test "dispatches only the requested account's contact digest" do
    first_user = users(:one)
    second_user = users(:two)
    first_delivery = create_contact_delivery(people(:ada), user: first_user, reminder_on: Date.new(2026, 8, 8))
    second_delivery = create_contact_delivery(people(:bob), user: second_user, reminder_on: Date.new(2026, 8, 8))

    assert_enqueued_jobs 1, only: ContactReminderDigestEmailJob do
      ReminderDeliveryDispatchJob.perform_now(
        first_user.id, at: local_time(first_user, Date.new(2026, 8, 8), 8)
      )
    end

    assert first_delivery.reload.contact_reminder_digest
    assert_nil second_delivery.reload.contact_reminder_digest
  end

  test "does not send a second digest when more contact work arrives that day" do
    user = users(:one)
    first = create_contact_delivery(people(:ada), user:, reminder_on: Date.new(2026, 8, 8))
    at = local_time(user, Date.new(2026, 8, 8), 8)
    ReminderDeliveryDispatchJob.perform_now(user.id, at:)
    digest = first.reload.contact_reminder_digest
    digest.update!(status: ContactReminderDigest::DELIVERED_STATUS, delivered_at: at)
    late = create_contact_delivery(people(:grace), user:, reminder_on: Date.new(2026, 8, 8))
    clear_enqueued_jobs

    assert_no_enqueued_jobs do
      ReminderDeliveryDispatchJob.perform_now(user.id, at: at + 1.hour)
    end

    assert_nil late.reload.contact_reminder_digest
  end

  test "leaves failed digest retries to the delivery job" do
    user = users(:one)
    delivery = create_contact_delivery(people(:ada), user:, reminder_on: Date.new(2026, 8, 8))
    at = local_time(user, Date.new(2026, 8, 8), 8)
    digest = ContactReminderDigest::Builder.call(user:, at:)
    digest.update!(status: ContactReminderDigest::FAILED_STATUS, failed_at: at)

    assert_no_enqueued_jobs do
      ReminderDeliveryDispatchJob.perform_now(user.id, at: at + 1.hour)
    end

    assert_equal digest, delivery.reload.contact_reminder_digest
  end

  private

  def create_contact_delivery(person, user:, reminder_on:)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: reminder_on - 7.days)
    ReminderDelivery.create!(
      user:, source: person, channel: "email", reminder_on:, occurrence_on: reminder_on
    )
  end

  def local_time(user, date, hour, minute = 0)
    Time.use_zone(user.time_zone) { Time.zone.local(date.year, date.month, date.day, hour, minute).utc }
  end
end
