require "test_helper"

class ReminderMailerPreviewTest < ActionMailer::TestCase
  test "renders representative reminder emails without creating reminder records" do
    user = User.create!(
      email_address: Rails.application.config.x.development_seed_email_address,
      password: "preview-password",
      time_zone: "UTC"
    )
    person = user.people.create!(name: "Preview Person")
    5.times { |index| user.people.create!(name: "Preview Person #{index + 2}") }
    Entry::Birthday.create!(person:, entry_date: Date.new(1990, 9, 14))
    record_counts = reminder_record_counts

    preview = ReminderMailerPreview.new
    messages = [
      preview.contact_digest,
      preview.contact_digest_single,
      preview.birthday,
      preview.significant_date
    ]

    assert messages.all?(&:multipart?)
    assert_equal record_counts, reminder_record_counts
  end

  private

  def reminder_record_counts
    [ KeepInTouchSetting.count, EntryReminder.count, ReminderDelivery.count, ContactReminderDigest.count ]
  end
end
