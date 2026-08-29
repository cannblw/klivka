class BirthdayMonthSectionComponent < ViewComponent::Base
  def initialize(month:, birthdays:, year:, heading_level: 2)
    @month = month
    @birthdays = birthdays
    @year = year
    @heading_level = heading_level
  end

  private

  attr_reader :month, :birthdays, :year, :heading_level

  def month_name
    I18n.t("date.month_names").fetch(month)
  end

  def heading_tag
    "h#{heading_level}"
  end
end
