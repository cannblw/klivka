require "test_helper"

class DemoResetJobTest < ActiveJob::TestCase
  test "resets demo data and profile settings after the demo is old and idle" do
    now = Time.zone.parse("2026-08-04 12:00:00")

    with_demo_mode do |demo_user|
      DemoPersonaSeedData.call(user: demo_user)
      demo_user.friends.create!(name: "Visitor addition")
      demo_user.update!(
        locale: "es",
        theme: "dark",
        time_zone: "Europe/Madrid",
        reminder_in_app_enabled: false,
        reminder_email_enabled: false,
        default_reminder_lead_value: 4,
        default_reminder_lead_unit: "days"
      )
      state = DemoState.create!(
        key: DemoState::SHARED_KEY,
        started_at: now - 25.hours,
        last_activity_at: now - 31.minutes
      )

      DemoResetJob.perform_now(at: now)

      demo_user.reload
      assert_equal DemoPersonaSeedData::FRIEND_COUNT, demo_user.friends.count
      assert_not demo_user.friends.exists?(name: "Visitor addition")
      assert_nil demo_user.locale
      assert_nil demo_user.theme
      assert_equal Rails.application.config.x.default_time_zone, demo_user.time_zone
      assert_equal Rails.application.config.x.reminder_default_in_app_enabled, demo_user.reminder_in_app_enabled
      assert_equal Rails.application.config.x.reminder_default_email_enabled, demo_user.reminder_email_enabled
      assert_equal Rails.application.config.x.reminder_default_lead_value, demo_user.default_reminder_lead_value
      assert_equal Rails.application.config.x.reminder_default_lead_unit, demo_user.default_reminder_lead_unit
      assert_equal now, state.reload.started_at
      assert_equal now, state.last_activity_at
    end
  end

  test "keeps visitor changes while an old demo is still active" do
    now = Time.zone.parse("2026-08-04 12:00:00")

    with_demo_mode do |demo_user|
      visitor_friend = demo_user.friends.create!(name: "Active visitor addition")
      state = DemoState.create!(
        key: DemoState::SHARED_KEY,
        started_at: now - 25.hours,
        last_activity_at: now - 10.minutes
      )

      DemoResetJob.perform_now(at: now)

      assert demo_user.friends.exists?(visitor_friend.id)
      assert_equal now - 25.hours, state.reload.started_at
    end
  end

  test "does nothing when demo mode is disabled" do
    assert_no_difference [ "DemoState.count", "Friend.count" ] do
      DemoResetJob.perform_now
    end
  end

  test "recurring reset uses the configured check interval" do
    with_demo_mode do
      recurring_tasks = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml"))

      assert_equal "every 15 minutes", recurring_tasks.dig("production", "reset_shared_demo", "schedule")
      assert_equal "DemoResetJob", recurring_tasks.dig("production", "reset_shared_demo", "class")
    end
  end

  test "does not schedule demo resets for regular self-hosted instances" do
    recurring_tasks = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml"))

    assert_nil recurring_tasks.dig("production", "reset_shared_demo")
  end
end
