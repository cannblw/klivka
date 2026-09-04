class PeopleQuery
  SORTS = PeopleSorter::SORTS
  DEFAULT_SORT = PeopleSorter::DEFAULT_SORT
  DEFAULT_STATE = "active"
  BIRTHDAY_FILTERS = %w[missing year_unknown].freeze
  LAST_CONTACT_FILTERS = %w[never within_30_days 31_to_90_days 91_to_180_days over_180_days].freeze
  STATE_FILTERS = %w[active archived all].freeze
  CONTACT_REMINDER_FILTERS = %w[on off].freeze
  DATE_REMINDER_FILTERS = %w[present missing].freeze
  UNCATEGORIZED_FILTER = "uncategorized"
  BLOCK_TYPES = {
    "phone" => Entry::Phone.sti_name,
    "email" => Entry::Email.sti_name,
    "note" => Entry::Note.sti_name,
    "birthday" => Entry::Birthday.sti_name,
    "date" => Entry::Date.sti_name,
    "first_met" => Entry::FirstMet.sti_name,
    "gift_list" => Entry::GiftList.sti_name
  }.freeze
  FILTER_KEYS = %i[birthday last_contact category state has_blocks missing_blocks contact_reminder date_reminder].freeze

  def self.call(user, query, sort: DEFAULT_SORT, filters: {}, on: user.local_date)
    new(user, query, sort:, filters:, on:).call
  end

  def initialize(user, query, sort: DEFAULT_SORT, filters: {}, on: user.local_date)
    @user = user
    @query = PersonNameNormalizer.call(query)
    @sort = SORTS.key?(sort.to_s) ? sort.to_s : DEFAULT_SORT
    @filters = normalize_filters(filters)
    @on = on
  end

  attr_reader :filters, :query, :sort

  def call
    scope = PeopleFilter.new(user, filters:, on:).call
    people = PeopleSorter.new(scope, sort:).call
    PersonSearch.new(query).call(people)
  end

  def filtered?
    filters.any? { |key, value| key == :state ? value != DEFAULT_STATE : value.present? }
  end

  def url_params
    {
      query: query.presence,
      sort: (sort unless sort == DEFAULT_SORT),
      birthday: filters[:birthday],
      last_contact: filters[:last_contact],
      category: filters[:category],
      state: (filters[:state] unless filters[:state] == DEFAULT_STATE),
      has_blocks: filters[:has_blocks].presence,
      missing_blocks: filters[:missing_blocks].presence,
      contact_reminder: filters[:contact_reminder],
      date_reminder: filters[:date_reminder]
    }.compact
  end

  private

  attr_reader :on, :user

  def normalize_filters(filters)
    values = filters.to_h.symbolize_keys.slice(*FILTER_KEYS)
    {
      birthday: values[:birthday].to_s.presence_in(BIRTHDAY_FILTERS),
      last_contact: values[:last_contact].to_s.presence_in(LAST_CONTACT_FILTERS),
      category: normalize_category_filter(values[:category]),
      state: values[:state].to_s.presence_in(STATE_FILTERS) || DEFAULT_STATE,
      has_blocks: normalize_block_filters(values[:has_blocks]),
      missing_blocks: normalize_block_filters(values[:missing_blocks]),
      contact_reminder: values[:contact_reminder].to_s.presence_in(CONTACT_REMINDER_FILTERS),
      date_reminder: values[:date_reminder].to_s.presence_in(DATE_REMINDER_FILTERS)
    }
  end

  def normalize_block_filters(values)
    selected = Array(values).map(&:to_s).uniq
    BLOCK_TYPES.keys.select { selected.include?(_1) }
  end

  def normalize_category_filter(value)
    value = value.to_s
    return UNCATEGORIZED_FILTER if value == UNCATEGORIZED_FILTER

    category_id = Integer(value, exception: false)
    category_id.to_s if category_id&.positive? && user.categories.where(id: category_id).exists?
  end
end
