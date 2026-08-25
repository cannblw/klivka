require "test_helper"

class BirthdayFieldsComponentTest < ViewComponent::TestCase
  test "renders required month and day with optional year and age" do
    entry = Entry::Birthday.new(friend: friends(:ada), entry_month: "5", entry_day: "12")

    render_inline BirthdayFieldsComponent.new(form: form_for(entry), entry:, today: Date.new(2026, 8, 25))

    assert_selector "[data-controller='birthday-fields'][data-birthday-fields-today-value='2026-08-25']"
    assert_selector "input[type='hidden'][name='entry[birthday_input_basis]'][data-birthday-fields-target='basis']", visible: :all
    assert_selector "select[name='entry[entry_month]'][required][data-birthday-fields-target='month'] option[selected][value='5']", text: "May"
    assert_selector "input[name='entry[entry_day]'][required][min='1'][max='31'][value='12'][data-birthday-fields-target='day']"
    assert_selector "input[name='entry[entry_year]'][min='1'][max='2026'][data-birthday-fields-target='year']"
    assert_selector "input[name='entry[current_age]'][min='0'][max='2025'][data-birthday-fields-target='age']"
    assert_text "Enter whichever one you know, or leave both blank."
    assert_selector "[data-birthday-fields-target='preview']", count: 0
  end

  test "renders a known year when editing a birthday" do
    entry = entries(:ada_birthday)

    travel_to Date.new(2026, 8, 25) do
      render_inline BirthdayFieldsComponent.new(form: form_for(entry), entry:)
    end

    assert_selector "select[name='entry[entry_month]'] option[selected][value='12']", text: "December"
    assert_selector "input[name='entry[entry_day]'][value='10']"
    assert_selector "input[name='entry[entry_year]'][value='1815']"
    assert_selector "input[name='entry[current_age]'][value='210']"
  end

  test "keeps submitted values and displays a date error" do
    entry = Entry::Birthday.new(
      friend: friends(:ada), entry_month: "2", entry_day: "30", current_age: "20"
    )
    entry.validate

    render_inline BirthdayFieldsComponent.new(form: form_for(entry), entry:)

    assert_selector "select[name='entry[entry_month]'] option[selected][value='2']"
    assert_selector "input[name='entry[entry_day]'][value='30']"
    assert_selector "input[name='entry[current_age]'][value='20']"
    assert_selector ".text-red-600", count: 1
  end

  private

  def form_for(entry)
    ActionView::Helpers::FormBuilder.new(:entry, entry, vc_test_controller.view_context, {})
  end
end
