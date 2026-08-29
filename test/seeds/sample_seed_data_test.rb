require "test_helper"

class SampleSeedDataTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "seed-data@example.com", password: "password")
  end

  test "creates a varied set of one hundred people" do
    SampleSeedData.call(user: @user)

    assert_equal 100, @user.people.count
    assert_equal 98, @user.people.active.count
    assert_equal 2, @user.people.archived.count
    assert_equal 12, @user.people.left_joins(:entries).where(entries: { id: nil }).count
    assert_equal 50, @user.people.joins(:entries).where(entries: { type: "Entry::Phone" }).count
    assert_equal 40, @user.people.joins(:entries).where(entries: { type: "Entry::Note" }).count
    assert_equal 30, @user.people.joins(:entries).where(entries: { type: "Entry::Birthday" }).count
    assert_equal 32, @user.people.joins(:entries).where(entries: { type: "Entry::Email" }).count
    assert_equal 153, @user.people.joins(:entries).count
  end

  test "archives two Faker-generated people while preserving their generated entries" do
    SampleSeedData.call(user: @user)

    archived_people = @user.people.archived.order(:archived_at).to_a

    assert_equal SampleSeedData::ARCHIVED_PERSON_COUNT, archived_people.size
    assert archived_people.all? { |person| person.entries.any? }
    assert archived_people.all? { |person| person.archived_at.present? }
  end

  test "creates people for contact action scenarios" do
    SampleSeedData.call(user: @user)

    contact_actions, phone_overflow, email_overflow, email_entry = @user.people.order(:id).first(4)

    assert_equal 3, contact_actions.entries.where(type: "Entry::Phone").count
    assert_equal 3, contact_actions.entries.where(type: "Entry::Email").count
    assert_equal 3, phone_overflow.entries.where(type: "Entry::Phone").count
    assert_equal 3, email_overflow.entries.where(type: "Entry::Email").count
    email = email_entry.entries.find_by!(type: "Entry::Email")
    assert email.valid?
    assert_equal "Work", email.label
  end

  test "creates mock contact, birthday, and date reminders for interface development" do
    SampleSeedData.call(user: @user)

    reminders = InAppRemindersQuery.call(user: @user)

    assert_equal 3, reminders.contacts.size
    assert_equal 1, reminders.birthdays.size
    assert_equal 1, reminders.dates.size
    assert_equal "Sample date reminder", reminders.dates.first.source.entry.label
  end

  test "replaces the seed user's people without changing other accounts" do
    other_user = User.create!(email_address: "other-seed-data@example.com", password: "password")
    other_person = other_user.people.create!(name: "Other Person")

    SampleSeedData.call(user: @user)
    replaced_person = @user.people.first
    seeded_email = @user.people.order(:id).fourth.entries.find_by!(type: "Entry::Email").email
    replaced_person.update!(name: "Changed Seed Person")
    @user.people.create!(name: "Temporary Person")

    SampleSeedData.call(user: @user)

    assert_equal 100, @user.people.count
    assert_equal 153, Entry.joins(:person).where(people: { user_id: @user.id }).count
    assert_not @user.people.exists?(name: "Changed Seed Person")
    assert_not @user.people.exists?(name: "Temporary Person")
    assert_equal 3, @user.people.order(:id).third.entries.where(type: "Entry::Email").count
    assert_equal seeded_email, @user.people.order(:id).fourth.entries.find_by!(type: "Entry::Email").email
    assert_equal other_person, other_user.people.find_by(name: "Other Person")
  end
end
