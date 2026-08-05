# == Schema Information
#
# Table name: friends
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_friends_on_user_id           (user_id)
#  index_friends_on_user_id_and_slug  (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Friend < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :scoped ], scope: :user

  belongs_to :user
  has_many :entries, dependent: :destroy
  has_many :interactions, dependent: :destroy

  validates :name, presence: true

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  def initials
    name.split.take(2).map { |part| part[0] }.join.upcase
  end
end
