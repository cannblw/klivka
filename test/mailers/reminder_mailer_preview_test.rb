require "test_helper"

class ReminderMailerPreviewTest < ActionMailer::TestCase
  test "renders every reminder email from basic development seed data without creating reminder records" do
    user = User.create!(
      email_address: Rails.application.config.x.development_seed_email_address,
      password: "preview-password",
      time_zone: "UTC"
    )
    friend = user.friends.create!(name: "Preview Friend")
    Entry::Birthday.create!(friend:, entry_date: Date.new(1990, 9, 14))
    record_counts = reminder_record_counts

    preview = ReminderMailerPreview.new
    messages = [
      preview.keep_in_touch,
      preview.keep_in_touch_spanish,
      preview.birthday,
      preview.birthday_spanish,
      preview.significant_date,
      preview.significant_date_spanish
    ]

    assert messages.all?(&:multipart?)
    assert_equal record_counts, reminder_record_counts
  end

  private

  def reminder_record_counts
    [ KeepInTouchSetting.count, EntryReminder.count, ReminderDelivery.count ]
  end
end
