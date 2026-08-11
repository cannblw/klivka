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
class DemoState < ApplicationRecord
  SHARED_KEY = "shared".freeze

  validates :key, presence: true, inclusion: { in: [ SHARED_KEY ] }, uniqueness: true
  validates :started_at, :last_activity_at, presence: true
  validates :last_activity_at, comparison: { greater_than_or_equal_to: :started_at }

  def self.current(at: Time.current)
    find_or_create_by!(key: SHARED_KEY) do |state|
      state.started_at = at
      state.last_activity_at = at
    end
  end

  def record_activity!(at: Time.current)
    with_lock do
      update!(last_activity_at: at) if at > last_activity_at
    end
  end

  def reset_due?(at: Time.current)
    hard_maximum_reached?(at:) || minimum_age_reached?(at:) && idle_period_reached?(at:)
  end

  def begin_new_cycle!(at: Time.current)
    update!(started_at: at, last_activity_at: at)
  end

  private

  def minimum_age_reached?(at:)
    started_at + Rails.application.config.x.demo_reset_minimum_age <= at
  end

  def idle_period_reached?(at:)
    last_activity_at + Rails.application.config.x.demo_reset_idle_period <= at
  end

  def hard_maximum_reached?(at:)
    started_at + Rails.application.config.x.demo_reset_maximum_age <= at
  end
end
