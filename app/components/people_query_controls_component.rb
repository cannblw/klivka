class PeopleQueryControlsComponent < ViewComponent::Base
  def initialize(search:, categories:, view:)
    @search = search
    @categories = categories
    @view = view
  end

  private

  attr_reader :search, :categories, :view

  delegate :filters, to: :search

  def sort_choices
    PersonSearch::SORTS.keys.map do |sort|
      value = sort == PersonSearch::DEFAULT_SORT ? "" : sort
      [ t("people.index.sort_options.#{sort}"), value ]
    end
  end

  def birthday_choices
    filter_choices(:birthday, PersonSearch::BIRTHDAY_FILTERS)
  end

  def last_contact_choices
    filter_choices(:last_contact, PersonSearch::LAST_CONTACT_FILTERS)
  end

  def state_choices
    PersonSearch::STATE_FILTERS.map do |state|
      [ t("people.index.filters.state.#{state}"), state ]
    end
  end

  def contact_reminder_choices
    filter_choices(:contact_reminder, PersonSearch::CONTACT_REMINDER_FILTERS)
  end

  def date_reminder_choices
    filter_choices(:date_reminder, PersonSearch::DATE_REMINDER_FILTERS)
  end

  def category_choices
    choices = [ [ t("people.index.filters.any"), "" ], [ t("people.index.filters.category.uncategorized"), PersonSearch::UNCATEGORIZED_FILTER ] ]
    choices.concat(categories.map { [ _1.name, _1.id.to_s ] })
  end

  def block_types
    PersonSearch::BLOCK_TYPES.keys
  end

  def block_label(block)
    t("entries.kinds.#{block}")
  end

  def filter_choices(filter, values)
    [ [ t("people.index.filters.any"), "" ] ] + values.map do |value|
      [ t("people.index.filters.#{filter}.#{value}"), value ]
    end
  end
end
