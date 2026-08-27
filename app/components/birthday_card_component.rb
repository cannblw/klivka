class BirthdayCardComponent < ViewComponent::Base
  with_collection_parameter :birthday

  def initialize(birthday:, year: Date.current.year, return_month: nil)
    @birthday = birthday
    @year = year
    @return_month = return_month
  end

  private

  attr_reader :birthday, :year, :return_month

  def person
    birthday.person
  end

  def occurrence_on
    @occurrence_on ||= birthday.occurrence_on(year:)
  end

  def age
    birthday.age(on: occurrence_on)
  end

  def person_path
    helpers.person_path(person, from: "birthdays", month: return_month)
  end
end
