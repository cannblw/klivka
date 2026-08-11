require "test_helper"

# == Schema Information
#
# Table name: demo_states
#
#  id               :integer          not null, primary key
#  key              :string           not null
#  last_activity_at :datetime         not null
#  started_at       :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_demo_states_on_key  (key) UNIQUE
#
class DemoStateTest < ActiveSupport::TestCase
  test "creates one shared state with the supplied start time" do
    start_time = Time.zone.parse("2026-08-01 10:00:00")

    state = DemoState.current(at: start_time)

    assert_equal DemoState::SHARED_KEY, state.key
    assert_equal start_time, state.started_at
    assert_equal start_time, state.last_activity_at
    assert_equal state, DemoState.current(at: start_time + 1.hour)
  end

  test "waits for both minimum age and visitor inactivity" do
    start_time = Time.zone.parse("2026-08-01 10:00:00")
    state = DemoState.create!(
      key: DemoState::SHARED_KEY,
      started_at: start_time,
      last_activity_at: start_time
    )

    assert_not state.reset_due?(at: start_time + 24.hours - 1.second)
    assert state.reset_due?(at: start_time + 24.hours)

    state.update!(last_activity_at: start_time + 23.hours + 45.minutes)
    assert_not state.reset_due?(at: start_time + 24.hours)
    assert state.reset_due?(at: start_time + 24.hours + 15.minutes)
  end

  test "requires a reset at the hard maximum despite recent activity" do
    start_time = Time.zone.parse("2026-08-01 10:00:00")
    state = DemoState.create!(
      key: DemoState::SHARED_KEY,
      started_at: start_time,
      last_activity_at: start_time + 71.hours + 59.minutes
    )

    assert_not state.reset_due?(at: start_time + 72.hours - 1.second)
    assert state.reset_due?(at: start_time + 72.hours)
  end

  test "records only newer visitor activity" do
    start_time = Time.zone.parse("2026-08-01 10:00:00")
    state = DemoState.current(at: start_time)

    state.record_activity!(at: start_time - 1.minute)
    assert_equal start_time, state.reload.last_activity_at

    state.record_activity!(at: start_time + 1.minute)
    assert_equal start_time + 1.minute, state.reload.last_activity_at
  end
end
