# == Schema Information
#
# Table name: categories
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  normalized_name :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_categories_on_user_id                      (user_id)
#  index_categories_on_user_id_and_normalized_name  (user_id,normalized_name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class Category < ApplicationRecord
  belongs_to :user
  has_many :friends, dependent: :nullify

  before_validation :normalize_name

  validates :name, presence: true, length: { maximum: FriendCrm::STRING_MAX_LENGTH }
  validates :normalized_name, presence: true, uniqueness: { scope: :user_id }

  private

  def normalize_name
    self.name = StringNormalizer.call(name)
    self.normalized_name = name.downcase
  end
end
