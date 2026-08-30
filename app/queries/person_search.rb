class PersonSearch
  SORTS = {
    "name" => { name: :asc, id: :asc },
    "recently_added" => { created_at: :desc, name: :asc, id: :asc },
    "recently_updated" => { updated_at: :desc, name: :asc, id: :asc },
    "recently_contacted" => nil,
    "least_recently_contacted" => nil
  }.freeze
  DEFAULT_SORT = "name"
  DEFAULT_STATE = "active"
  BIRTHDAY_FILTERS = %w[missing year_unknown].freeze
  LAST_CONTACT_FILTERS = %w[
    never
    within_30_days
    31_to_90_days
    91_to_180_days
    over_180_days
  ].freeze
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
  FILTER_KEYS = %i[
    birthday
    last_contact
    category
    state
    has_blocks
    missing_blocks
    contact_reminder
    date_reminder
  ].freeze

  # Fixed score bands ensure literal matches always rank ahead of fuzzy matches.
  MATCH_SCORE_PERCENTAGES = {
    exact: 100,
    name_prefix: 90,
    token_prefix: 85,
    substring: 80,
    initials: 75,
    fuzzy: 70
  }.freeze
  MINIMUM_FUZZY_QUERY_LENGTH = 2
  # Short queries need stricter thresholds because a few shared characters otherwise produce noisy matches.
  TWO_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.85
  THREE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.78
  FOUR_OR_MORE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.65

  def self.call(user, query, sort: DEFAULT_SORT, filters: {}, on: user.local_date)
    new(user, query, sort:, filters:, on:).call
  end

  def initialize(user, query, sort: DEFAULT_SORT, filters: {}, on: user.local_date)
    @user = user
    @query = PersonNameNormalizer.call(query)
    @query_tokens = @query.split
    @sort = SORTS.key?(sort.to_s) ? sort.to_s : DEFAULT_SORT
    @filters = normalize_filters(filters)
    @on = on
    @people = apply_filters(people_for_state)
  end

  attr_reader :query, :sort, :filters

  def filtered?
    filters.any? do |key, value|
      key == :state ? value != DEFAULT_STATE : value.present?
    end
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

  def call
    ordered_people = people_in_sort_order
    return ordered_people if query.blank?

    ranked_person_ids = ordered_people.map { [ _1.id, _1.name ] }
      .each_with_index
      .filter_map do |(id, name), sort_position|
        normalized_name = PersonNameNormalizer.call(name)
        candidate_score = score(normalized_name, normalized_name.split)
        [ id, candidate_score, sort_position ] if candidate_score
      end
      .sort_by { |id, candidate_score, sort_position| [ -candidate_score, sort_position ] }
      .first(Rails.application.config.x.person_search_max_results)
      .map(&:first)

    return [] if ranked_person_ids.empty?

    people_by_id = people.where(id: ranked_person_ids).index_by(&:id)
    ranked_person_ids.filter_map { |id| people_by_id[id] }
  end

  private

  attr_reader :user, :people, :query_tokens, :on

  def people_in_sort_order
    return people.order(SORTS.fetch(sort)).to_a if SORTS.fetch(sort)

    latest_contacts = Interaction.where(person_id: people.select(:id)).group(:person_id).maximum(:occurred_on)
    people.to_a.sort_by do |person|
      last_contact = latest_contacts[person.id]
      contact_order = if sort == "recently_contacted"
        [ last_contact ? 0 : 1, last_contact ? -last_contact.jd : 0 ]
      else
        [ last_contact ? 1 : 0, last_contact&.jd || 0 ]
      end

      [ *contact_order, PersonNameNormalizer.call(person.name), person.id ]
    end
  end

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

  def people_for_state
    case filters[:state]
    when "archived" then user.people.archived
    when "all" then user.people
    else user.people.active
    end
  end

  def apply_filters(scope)
    scope = filter_by_category(scope)
    scope = filter_by_birthday(scope)
    scope = filter_by_last_contact(scope)
    scope = filter_by_blocks(scope)
    scope = filter_by_contact_reminder(scope)
    filter_by_date_reminder(scope)
  end

  def filter_by_category(scope)
    case filters[:category]
    when UNCATEGORIZED_FILTER then scope.where(category_id: nil)
    when nil then scope
    else scope.where(category_id: filters[:category])
    end
  end

  def filter_by_birthday(scope)
    birthday_people = Entry::Birthday.where(person_id: tenant_person_ids)

    case filters[:birthday]
    when "missing" then scope.where.not(id: birthday_people.select(:person_id))
    when "year_unknown" then scope.where(id: birthday_people.where(birthday_year_known: false).select(:person_id))
    else scope
    end
  end

  def filter_by_last_contact(scope)
    interactions = Interaction.where(person_id: tenant_person_ids)
    return scope.where.not(id: interactions.select(:person_id)) if filters[:last_contact] == "never"
    return scope unless filters[:last_contact]

    latest_interaction = Interaction.arel_table[:occurred_on].maximum
    latest_interactions = interactions.group(:person_id)

    latest_interactions = case filters[:last_contact]
    when "within_30_days"
      latest_interactions.having(latest_interaction.between((on - 30.days)..on))
    when "31_to_90_days"
      latest_interactions.having(latest_interaction.between((on - 90.days)..(on - 31.days)))
    when "91_to_180_days"
      latest_interactions.having(latest_interaction.between((on - 180.days)..(on - 91.days)))
    when "over_180_days"
      latest_interactions.having(latest_interaction.lt(on - 180.days))
    end

    scope.where(id: latest_interactions.select(:person_id))
  end

  def filter_by_blocks(scope)
    filters[:has_blocks].each do |block|
      entries = Entry.where(person_id: tenant_person_ids, type: BLOCK_TYPES.fetch(block))
      scope = scope.where(id: entries.select(:person_id))
    end

    filters[:missing_blocks].each do |block|
      entries = Entry.where(person_id: tenant_person_ids, type: BLOCK_TYPES.fetch(block))
      scope = scope.where.not(id: entries.select(:person_id))
    end

    scope
  end

  def filter_by_contact_reminder(scope)
    return scope unless filters[:contact_reminder]

    settings = KeepInTouchSetting.where(person_id: tenant_person_ids)
    enabled_settings = settings.where.not(enabled_on: nil)
    disabled_settings = settings.where(enabled_on: nil)

    if user.contact_reminders_enabled?
      filters[:contact_reminder] == "on" ?
        scope.where.not(id: disabled_settings.select(:person_id)) :
        scope.where(id: disabled_settings.select(:person_id))
    elsif filters[:contact_reminder] == "on"
      scope.where(id: enabled_settings.select(:person_id))
    else
      scope.where.not(id: enabled_settings.select(:person_id))
    end
  end

  def filter_by_date_reminder(scope)
    return scope unless filters[:date_reminder]

    dates = Entry.where(person_id: tenant_person_ids, type: Entry::Date.sti_name)
    reminded_entry_ids = EntryReminder.select(:entry_id)
    dates = if filters[:date_reminder] == "present"
      dates.where(id: reminded_entry_ids)
    else
      dates.where.not(id: reminded_entry_ids)
    end

    scope.where(id: dates.select(:person_id))
  end

  def tenant_person_ids
    @tenant_person_ids ||= user.people.select(:id)
  end

  def score(name, name_tokens)
    return MATCH_SCORE_PERCENTAGES[:exact] if name == query
    return MATCH_SCORE_PERCENTAGES[:name_prefix] if name.start_with?(query)
    return MATCH_SCORE_PERCENTAGES[:token_prefix] if token_prefix?(name_tokens)
    return MATCH_SCORE_PERCENTAGES[:substring] if name.include?(query)
    return MATCH_SCORE_PERCENTAGES[:initials] if initials(name_tokens).start_with?(compact_query)

    similarity = fuzzy_similarity(name, name_tokens)
    similarity * MATCH_SCORE_PERCENTAGES[:fuzzy] if similarity && similarity >= fuzzy_similarity_threshold
  end

  def token_prefix?(name_tokens)
    query_tokens.all? { |query_token| name_tokens.any? { |name_token| name_token.start_with?(query_token) } }
  end

  def initials(name_tokens)
    name_tokens.filter_map { |token| token[0] }.join
  end

  def fuzzy_similarity(name, name_tokens)
    return if compact_query.length < MINIMUM_FUZZY_QUERY_LENGTH

    similarities = [
      JaroWinkler.similarity(query, name, adj_table: true),
      JaroWinkler.similarity(compact_query, name.delete(" "), adj_table: true)
    ]

    token_similarities = query_tokens.map do |query_token|
      name_tokens.map { |name_token| JaroWinkler.similarity(query_token, name_token, adj_table: true) }.max
    end
    similarities << token_similarities.sum.fdiv(token_similarities.size) if token_similarities.any?

    similarities.max
  end

  def fuzzy_similarity_threshold
    case compact_query.length
    when 2 then TWO_CHARACTER_FUZZY_SIMILARITY_THRESHOLD
    when 3 then THREE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD
    else FOUR_OR_MORE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD
    end
  end

  def compact_query
    @compact_query ||= query_tokens.join
  end
end
