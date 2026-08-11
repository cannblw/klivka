require "securerandom"

class DemoSeedData
  def self.call(email_address: Rails.application.config.x.demo_user_email_address)
    new(email_address:).call
  end

  def initialize(email_address:)
    @email_address = email_address
  end

  def call
    User.transaction do
      user = User.find_or_initialize_by(email_address:)

      if user.new_record?
        user.password = SecureRandom.urlsafe_base64(48)
        user.save!
      end

      SampleSeedData.call(user:) if user.friends.none?
      user
    end
  end

  private

  attr_reader :email_address
end
