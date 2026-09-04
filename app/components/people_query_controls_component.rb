class PeopleQueryControlsComponent < ViewComponent::Base
  def initialize(search:, categories:, view:, grouping_available:)
    @search = search
    @categories = categories
    @view = view
    @grouping_available = grouping_available
  end

  private

  attr_reader :search, :categories, :view

  delegate :filters, to: :search

  def show_view_toggle?
    @grouping_available && search.query.blank? && !search.filtered?
  end

  def options_active?
    search.filtered? || search.sort != PeopleQuery::DEFAULT_SORT
  end

  def sort_choices
    PeopleQuery::SORTS.keys.map do |sort|
      value = sort == PeopleQuery::DEFAULT_SORT ? "" : sort
      [ t("people.index.sort_options.#{sort}"), value ]
    end
  end

  def birthday_choices
    filter_choices(:birthday, PeopleQuery::BIRTHDAY_FILTERS)
  end

  def last_contact_choices
    filter_choices(:last_contact, PeopleQuery::LAST_CONTACT_FILTERS)
  end

  def state_choices
    PeopleQuery::STATE_FILTERS.map do |state|
      [ t("people.index.filters.state.#{state}"), state ]
    end
  end

  def contact_reminder_choices
    filter_choices(:contact_reminder, PeopleQuery::CONTACT_REMINDER_FILTERS)
  end

  def date_reminder_choices
    filter_choices(:date_reminder, PeopleQuery::DATE_REMINDER_FILTERS)
  end

  def category_choices
    choices = [ [ t("people.index.filters.any"), "" ], [ t("people.index.filters.category.uncategorized"), PeopleQuery::UNCATEGORIZED_FILTER ] ]
    choices.concat(categories.map { [ _1.name, _1.id.to_s ] })
  end

  def block_types
    PeopleQuery::BLOCK_TYPES.keys
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
