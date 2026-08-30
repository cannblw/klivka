require "test_helper"

class ReminderMailerTest < ActionMailer::TestCase
  test "contact digest links to every previewed person and the complete reminder list" do
    digest = ContactReminderDigest.create!(user: users(:one), delivery_on: Date.new(2026, 8, 8))
    deliveries = [ people(:ada), people(:grace) ].map do |person|
      create_delivery(person, reminder_on: digest.delivery_on, contact_reminder_digest: digest)
    end

    mail = ReminderMailer.with(digest:, people: deliveries.map(&:source), count: deliveries.size).contact_digest

    assert_equal [ "one@example.com" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_predicate mail.subject, :present?
    assert_includes mail.html_part.body.to_s, 'src="http://localhost:3000/brand/klivka-logo.svg"'
    assert_includes mail.text_part.body.to_s, "http://localhost:3000/people/ada-lovelace"
    assert_includes mail.text_part.body.to_s, "http://localhost:3000/people/grace-hopper"
    assert_includes mail.text_part.body.to_s, "http://localhost:3000/reminders"
    assert_includes mail.text_part.body.to_s, "http://localhost:3000/settings/reminders#contact-reminders"
  end

  test "contact digest limits its email preview while retaining the complete count" do
    user = users(:one)
    digest = ContactReminderDigest.create!(user:, delivery_on: Date.new(2026, 8, 8))
    people = 6.times.map { |index| user.people.create!(name: "Digest person #{index}") }
    deliveries = people.map do |person|
      create_delivery(person, reminder_on: digest.delivery_on, contact_reminder_digest: digest)
    end

    preview_limit = Rails.application.config.x.contact_reminder_digest_preview_limit
    preview_people = deliveries.first(preview_limit).map(&:source)
    body = ReminderMailer.with(digest:, people: preview_people, count: deliveries.size).contact_digest.text_part.body.to_s

    people.first(preview_limit).each { |person| assert_includes body, person.name }
    assert_not_includes body, people.last.name
    assert_includes body, "6"
  end

  test "birthday email links to the person and includes the occurrence date" do
    delivery = create_delivery(entries(:ada_birthday), reminder_on: Date.new(2026, 12, 1), occurrence_on: Date.new(2026, 12, 10))

    mail = ReminderMailer.with(delivery:).birthday

    body = mail.text_part.body.to_s
    assert_predicate mail.subject, :present?
    assert_includes body, "/people/ada-lovelace"
    assert_includes body, I18n.l(delivery.occurrence_on, format: :long)
    assert_includes body, "/settings/reminders#birthday-reminders"
  end

  test "significant-date email includes its label and localized date" do
    entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7), content: { "label" => "Moving day" })
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    delivery = create_delivery(reminder, reminder_on: Date.new(2026, 9, 6), occurrence_on: Date.new(2026, 9, 7))

    mail = ReminderMailer.with(delivery:).significant_date

    body = mail.text_part.body.to_s
    assert_predicate mail.subject, :present?
    assert_includes body, "Moving day"
    assert_includes body, "/people/ada-lovelace"
    assert_includes body, I18n.l(delivery.occurrence_on, format: :long)
    assert_includes body, "/settings/reminders#date-reminders"
  end

  test "significant-date email renders without a label" do
    entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    delivery = create_delivery(reminder, reminder_on: Date.new(2026, 9, 6), occurrence_on: Date.new(2026, 9, 7))

    mail = ReminderMailer.with(delivery:).significant_date

    assert_predicate mail.subject, :present?
    assert_includes mail.text_part.body.to_s, "/people/ada-lovelace"
    assert_not_includes mail.text_part.body.to_s, "translation missing"
  end

  private

  def create_delivery(source, reminder_on:, occurrence_on: reminder_on, contact_reminder_digest: nil)
    ReminderDelivery.create!(
      user: users(:one), source:, channel: "email", reminder_on:, occurrence_on:, contact_reminder_digest:
    )
  end
end
