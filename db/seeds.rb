# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Development-only default account so the app is usable right after bin/setup
if Rails.env.development?
  admin = User.find_or_initialize_by(email_address: Rails.application.config.x.development_seed_email_address)
  admin.password = Rails.application.config.x.development_seed_password
  admin.save!

  SampleSeedData.call(user: admin)
end

if Rails.application.config.x.demo_mode
  DemoSeedData.call
end
