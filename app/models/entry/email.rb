# == Schema Information
#
# Table name: entries
#
#  id                  :integer          not null, primary key
#  birthday_year_known :boolean
#  content             :json
#  entry_date          :date
#  position            :integer          default(0), not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  friend_id           :integer          not null
#
# Indexes
#
#  index_entries_on_entry_date               (entry_date)
#  index_entries_on_friend_id                (friend_id)
#  index_entries_on_friend_id_and_position   (friend_id,position)
#  index_entries_on_friend_id_for_birthday   (friend_id) UNIQUE WHERE type = 'Entry::Birthday'
#  index_entries_on_friend_id_for_first_met  (friend_id) UNIQUE WHERE type = 'Entry::FirstMet'
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class Entry::Email < Entry
  self.vcard_import_property = :email

  store_accessor :content, :email, :label

  before_validation :normalize_contact_fields

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  private

  def normalize_contact_fields
    self.email = email.to_s.strip.downcase if email
    self.label = label.to_s.strip.presence if label
  end
end
