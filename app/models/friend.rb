# == Schema Information
#
# Table name: friends
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :integer
#  user_id     :integer          not null
#
# Indexes
#
#  index_friends_on_category_id       (category_id)
#  index_friends_on_user_id           (user_id)
#  index_friends_on_user_id_and_slug  (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  category_id  (category_id => categories.id) ON DELETE => nullify
#  user_id      (user_id => users.id)
#
class Friend < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :scoped, FriendlyId::UnicodeSlug ], scope: :user

  belongs_to :user
  belongs_to :category, optional: true
  has_many :entries, dependent: :destroy
  has_many :interactions, dependent: :destroy
  has_one :keep_in_touch_setting, dependent: :destroy

  validates :name, presence: true, length: { maximum: FriendCrm::STRING_MAX_LENGTH }
  validate :category_belongs_to_user

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  def initials
    name.split.take(2).map { |part| part[0] }.join.upcase
  end

  private

  def category_belongs_to_user
    return if category.nil? || category.user_id == user_id

    errors.add(:category, :invalid)
  end
end
