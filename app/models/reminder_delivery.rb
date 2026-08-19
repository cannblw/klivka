# == Schema Information
#
# Table name: reminder_deliveries
#
#  id            :integer          not null, primary key
#  attempts      :integer          default(0), not null
#  cancelled_at  :datetime
#  channel       :string           not null
#  claim_token   :string
#  claimed_at    :datetime
#  delivered_at  :datetime
#  failed_at     :datetime
#  occurrence_on :date             not null
#  reminder_on   :date             not null
#  source_type   :string           not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  source_id     :integer          not null
#  user_id       :integer          not null
#
# Indexes
#
#  idx_on_status_channel_reminder_on_f9dde1d6e2          (status,channel,reminder_on)
#  index_reminder_deliveries_on_source_date_and_channel  (source_type,source_id,reminder_on,channel) UNIQUE
#  index_reminder_deliveries_on_user_id                  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class ReminderDelivery < ApplicationRecord
  IN_APP_CHANNEL = "in_app".freeze
  EMAIL_CHANNEL = "email".freeze
  CHANNELS = [ IN_APP_CHANNEL, EMAIL_CHANNEL ].freeze

  PENDING_STATUS = "pending".freeze
  DELIVERED_STATUS = "delivered".freeze
  FAILED_STATUS = "failed".freeze
  CANCELLED_STATUS = "cancelled".freeze
  STATUSES = [ PENDING_STATUS, DELIVERED_STATUS, FAILED_STATUS, CANCELLED_STATUS ].freeze

  SOURCE_TYPES = %w[KeepInTouchSetting EntryReminder].freeze

  belongs_to :user
  belongs_to :source, polymorphic: true

  validates :channel, inclusion: { in: CHANNELS }
  validates :status, inclusion: { in: STATUSES }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :reminder_on, :occurrence_on, presence: true
  validates :attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :claim_token, presence: true, if: :claimed_at?
  validates :claimed_at, presence: true, if: :claim_token?
  validates :channel, uniqueness: { scope: %i[source_type source_id reminder_on] }
  validate :source_belongs_to_user

  private

  def source_belongs_to_user
    return if source.blank? || user.blank?

    source_user = source.is_a?(KeepInTouchSetting) ? source.friend.user : source.entry.friend.user
    errors.add(:source, :invalid) unless source_user == user
  end
end
