require "test_helper"

class ReminderDeliveryDispatchJobTest < ActiveJob::TestCase
  test "enqueues due pending email deliveries for one account" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    due = ReminderDelivery.create!(user: users(:one), source: setting, channel: "email", reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8))
    future = ReminderDelivery.create!(user: users(:one), source: setting, channel: "email", reminder_on: Date.new(2026, 8, 9), occurrence_on: Date.new(2026, 8, 9))
    other_user = ReminderDelivery.create!(user: users(:two), source: people(:bob).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1)), channel: "email", reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 8))

    assert_enqueued_jobs 1, only: ReminderDeliveryEmailJob do
      ReminderDeliveryDispatchJob.perform_now(users(:one).id, at: Time.utc(2026, 8, 8, 12))
    end

    dispatched_arguments = enqueued_jobs.map { |job| ActiveJob::Arguments.deserialize(job.fetch(:args)) }
    assert_equal [ [ due.id ] ], dispatched_arguments
    assert_not_includes enqueued_jobs.map { |job| ActiveJob::Arguments.deserialize(job.fetch(:args)).first }, future.id
    assert_not_includes enqueued_jobs.map { |job| ActiveJob::Arguments.deserialize(job.fetch(:args)).first }, other_user.id
  end
end
