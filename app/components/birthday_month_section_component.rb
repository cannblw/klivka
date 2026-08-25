class BirthdayMonthSectionComponent < ViewComponent::Base
  def initialize(month:, birthdays:, year:, heading_level: 2, return_month: nil)
    @month = month
    @birthdays = birthdays
    @year = year
    @heading_level = heading_level
    @return_month = return_month
  end

  private

  attr_reader :month, :birthdays, :year, :heading_level, :return_month

  def month_name
    I18n.t("date.month_names").fetch(month)
  end

  def heading_tag
    "h#{heading_level}"
  end
end
