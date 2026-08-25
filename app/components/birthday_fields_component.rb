class BirthdayFieldsComponent < ViewComponent::Base
  def initialize(form:, entry:, today: Date.current)
    @form = form
    @entry = entry
    @today = today
  end

  private

  attr_reader :form, :entry, :today

  def month_choices
    (1..12).map { |month| [ t("date.month_names")[month], month ] }
  end

  def controller_values
    {
      data: {
        controller: "birthday-fields",
        birthday_fields_today_value: today.iso8601,
        birthday_fields_anchor_year_value: Entry::Birthday::UNKNOWN_YEAR_ANCHOR
      }
    }
  end
end
