require "test_helper"

class ReminderScanDispatcherJobTest < ActiveJob::TestCase
  test "enqueues one bounded-concurrency reminder scan for each account" do
    at = Time.utc(2026, 8, 12, 12)

    assert_enqueued_jobs User.count, only: ReminderScanJob do
      ReminderScanDispatcherJob.perform_now(at:)
    end

    enqueued_jobs.select { |job| job.fetch(:job) == ReminderScanJob }.each do |job|
      arguments = ActiveJob::Arguments.deserialize(job.fetch(:args))
      assert_equal "reminders", job.fetch(:queue)
      assert_equal at, arguments.second.fetch(:at)
    end
  end

  test "recurring reminder dispatch uses the configured interval" do
    recurring_tasks = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml"))

    task = recurring_tasks.dig("production", "dispatch_reminder_scans")
    assert_equal "every 60 minutes", task.fetch("schedule")
    assert_equal "ReminderScanDispatcherJob", task.fetch("class")
    assert_equal "background", task.fetch("queue")
  end

  test "the reminder queue has bounded worker concurrency" do
    queue_configuration = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/queue.yml"))
    workers = queue_configuration.dig("production", "workers")
    reminder_worker = workers.find do |worker|
      worker.fetch("queues") == [ "reminders" ]
    end

    assert_equal 5, reminder_worker.fetch("threads")
    assert workers.all? { |worker| worker.fetch("processes") == 1 }
  end
end
