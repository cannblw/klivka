class Entry::Email < Entry
  store_accessor :content, :email, :label

  before_validation :normalize_contact_fields

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  private

  def normalize_contact_fields
    self.email = email.to_s.strip.downcase if email
    self.label = label.to_s.strip.presence if label
  end
end
