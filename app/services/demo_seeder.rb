require "securerandom"

class DemoSeeder
  def self.call(email_address: Rails.application.config.x.demo_user_email_address)
    new(email_address:).call
  end

  def self.reset!(email_address: Rails.application.config.x.demo_user_email_address)
    new(email_address:).reset!
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

      DemoPersonaSeeder.call(user:) if user.people.none?
      DemoState.current
      user
    end
  end

  def reset!
    User.transaction do
      user = User.find_by!(email_address:)
      reset_profile(user)
      user.contact_methods.destroy_all
      ContactMethod.create_provided_for!(user)
      DemoPersonaSeeder.call(user:)
      user
    end
  end

  private

  attr_reader :email_address

  def reset_profile(user)
    user.update!(
      locale: nil,
      theme: nil,
      time_zone: Rails.application.config.x.default_time_zone,
      reminder_in_app_enabled: Rails.application.config.x.reminder_default_in_app_enabled,
      reminder_email_enabled: Rails.application.config.x.reminder_default_email_enabled,
      default_reminder_lead_value: Rails.application.config.x.reminder_default_lead_value,
      default_reminder_lead_unit: Rails.application.config.x.reminder_default_lead_unit,
      birthday_reminders_enabled: Rails.application.config.x.birthday_reminder_default_enabled,
      birthday_reminder_lead_value: Rails.application.config.x.reminder_default_lead_value,
      birthday_reminder_lead_unit: Rails.application.config.x.reminder_default_lead_unit
    )
  end
end
