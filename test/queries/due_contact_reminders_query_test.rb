require "test_helper"

class DueContactRemindersQueryTest < ActiveSupport::TestCase
  setup do
    @today = Date.new(2026, 8, 28)
    @user = User.create!(email_address: "due-reminders@example.com", password: "password", time_zone: "Europe/London")
  end

  test "returns inherited and individual contact reminders that are due" do
    @user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: @today - 7.days)
    inherited_person = @user.people.create!(name: "Inherited reminder")
    custom_person = @user.people.create!(name: "Custom reminder")
    custom_person.create_keep_in_touch_setting!(cadence: "daily", enabled_on: @today - 1.day)
    future_person = @user.people.create!(name: "Future reminder")
    future_person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: @today)
    off_person = @user.people.create!(name: "Reminder off")
    off_person.create_keep_in_touch_setting!(cadence: "weekly")

    results = DueContactRemindersQuery.call(user: @user, on: @today)

    assert_equal [ custom_person, inherited_person ], results.map(&:person)
    assert_equal [ @today, @today ], results.map(&:reminder_on)
  end

  test "uses the latest interaction and snooze when deciding whether contact is due" do
    @user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: @today - 1.month)
    recently_contacted = @user.people.create!(name: "Recently contacted")
    recently_contacted.interactions.create!(occurred_on: @today - 1.day)
    snoozed = @user.people.create!(name: "Snoozed", contact_reminder_snoozed_until: @today + 1.week)

    assert_empty DueContactRemindersQuery.call(user: @user, on: @today)
  end

  test "excludes archived people and people from other accounts" do
    @user.update!(contact_reminder_cadence: "daily", contact_reminders_enabled_on: @today - 1.day)
    archived = @user.people.create!(name: "Archived")
    archived.archive!
    other_user_person = users(:two).people.create!(name: "Other account")
    other_user_person.create_keep_in_touch_setting!(cadence: "daily", enabled_on: @today - 1.day)

    assert_empty DueContactRemindersQuery.call(user: @user, on: @today)
  end

  test "orders reminders by due date and then normalized person name" do
    earlier = @user.people.create!(name: "Zulu")
    earlier.create_keep_in_touch_setting!(cadence: "daily", enabled_on: @today - 2.days)
    accent_name = @user.people.create!(name: "Álvaro")
    accent_name.create_keep_in_touch_setting!(cadence: "daily", enabled_on: @today - 1.day)
    later_name = @user.people.create!(name: "Bea")
    later_name.create_keep_in_touch_setting!(cadence: "daily", enabled_on: @today - 1.day)

    results = DueContactRemindersQuery.call(user: @user, on: @today)

    assert_equal [ earlier, accent_name, later_name ], results.map(&:person)
  end

  test "loads latest interactions once for each person batch" do
    @user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: @today - 7.days)
    3.times { |index| @user.people.create!(name: "Person #{index}") }
    query_class = Class.new(DueContactRemindersQuery) do
      attr_reader :interaction_batch_count

      def initialize(...)
        super
        @interaction_batch_count = 0
      end

      private

      def latest_interactions_for(people)
        @interaction_batch_count += 1
        super
      end
    end
    query = query_class.new(user: @user, on: @today, batch_size: 2)

    query.call

    assert_equal 2, query.interaction_batch_count
  end
end
