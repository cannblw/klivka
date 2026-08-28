# == Schema Information
#
# Table name: contact_reminder_digests
#
#  id           :integer          not null, primary key
#  attempts     :integer          default(0), not null
#  canceled_at  :datetime
#  claim_token  :string
#  claimed_at   :datetime
#  delivered_at :datetime
#  delivery_on  :date             not null
#  failed_at    :datetime
#  status       :string           default("pending"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_contact_reminder_digests_on_status_and_delivery_on   (status,delivery_on)
#  index_contact_reminder_digests_on_user_id                  (user_id)
#  index_contact_reminder_digests_on_user_id_and_delivery_on  (user_id,delivery_on) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class ContactReminderDigest < ApplicationRecord
  PENDING_STATUS = "pending".freeze
  DELIVERED_STATUS = "delivered".freeze
  FAILED_STATUS = "failed".freeze
  CANCELED_STATUS = "canceled".freeze
  STATUSES = [ PENDING_STATUS, DELIVERED_STATUS, FAILED_STATUS, CANCELED_STATUS ].freeze

  belongs_to :user
  has_many :reminder_deliveries

  validates :delivery_on, presence: true, uniqueness: { scope: :user_id }
  validates :status, inclusion: { in: STATUSES }
  validates :attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :claim_token, presence: true, if: :claimed_at?
  validates :claimed_at, presence: true, if: :claim_token?
end
