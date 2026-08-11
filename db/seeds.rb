# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Development-only default account so the app is usable right after bin/setup
load Rails.root.join("db/seeds/sample_data.rb") if Rails.env.development? || Rails.application.config.x.demo_mode

if Rails.env.development?
  admin = User.find_or_create_by!(email_address: "admin@example.com") do |user|
    user.password = "admin"
  end

  SampleSeedData.call(user: admin)
end

if Rails.application.config.x.demo_mode
  load Rails.root.join("db/seeds/demo.rb")
  DemoSeedData.call
end
