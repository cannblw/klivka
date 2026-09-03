require "test_helper"

class ContactTrackingStatusComponentTest < ViewComponent::TestCase
  test "omits contact status when neither contact nor a reminder is tracked" do
    person = users(:one).people.create!(name: "Name Only")

    render_inline ContactTrackingStatusComponent.new(
      latest_interaction: nil,
      reminder: ContactReminder.for(person),
      today: person.user.local_date
    )

    assert_no_selector "#last-contacted"
  end

  test "states that no contact is logged when an individual reminder is active" do
    person = users(:one).people.create!(name: "Name Only")
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: person.user.local_date)

    render_inline ContactTrackingStatusComponent.new(
      latest_interaction: nil,
      reminder: ContactReminder.for(person),
      today: person.user.local_date
    )

    assert_selector "#last-contacted[data-contact-tracking-state='not-logged']", text: /No contact logged yet/
  end

  test "states that no contact is logged when an account reminder is inherited" do
    user = users(:one)
    user.update!(contact_reminders_enabled_on: user.local_date)
    person = user.people.create!(name: "Name Only")

    render_inline ContactTrackingStatusComponent.new(
      latest_interaction: nil,
      reminder: ContactReminder.for(person),
      today: user.local_date
    )

    assert_selector "#last-contacted[data-contact-tracking-state='not-logged']", text: /No contact logged yet/
  end

  test "omits contact status when a person opts out of an account reminder" do
    user = users(:one)
    user.update!(contact_reminders_enabled_on: user.local_date)
    person = user.people.create!(name: "Name Only")
    ContactReminder.for(person).opt_out!

    render_inline ContactTrackingStatusComponent.new(
      latest_interaction: nil,
      reminder: ContactReminder.for(person.reload),
      today: user.local_date
    )

    assert_no_selector "#last-contacted"
  end

  test "shows the latest contact even when reminders are off" do
    person = users(:one).people.create!(name: "Name Only")
    today = person.user.local_date
    interaction = person.interactions.create!(occurred_on: today - 2.days)

    render_inline ContactTrackingStatusComponent.new(
      latest_interaction: interaction,
      reminder: ContactReminder.for(person),
      today:
    )

    assert_selector "#last-contacted[data-contact-tracking-state='logged']", text: /Last contact/
    assert_selector "#last-contacted", text: /2 days ago/
  end

  test "shows contact recorded on the user's local date as today" do
    person = users(:one).people.create!(name: "Name Only")
    today = person.user.local_date
    interaction = person.interactions.create!(occurred_on: today)

    render_inline ContactTrackingStatusComponent.new(
      latest_interaction: interaction,
      reminder: ContactReminder.for(person),
      today:
    )

    assert_selector "#last-contacted[data-contact-tracking-state='logged']", text: /Last contact:\s+today/
  end
end
