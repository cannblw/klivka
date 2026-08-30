class BirthdayCardComponent < ViewComponent::Base
  with_collection_parameter :birthday

  def initialize(birthday:, year: Date.current.year)
    @birthday = birthday
    @year = year
  end

  private

  attr_reader :birthday, :year

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
    helpers.person_path(person)
  end
end
