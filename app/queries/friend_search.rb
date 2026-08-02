class FriendSearch
  SORTS = {
    "name" => { name: :asc, id: :asc },
    "recently_added" => { created_at: :desc, name: :asc, id: :asc },
    "recently_updated" => { updated_at: :desc, name: :asc, id: :asc }
  }.freeze
  DEFAULT_SORT = "name"

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
  THREE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.72
  FOUR_OR_MORE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.65

  def self.call(user, query, sort: DEFAULT_SORT)
    new(user, query, sort: sort).call
  end

  def initialize(user, query, sort: DEFAULT_SORT)
    @friends = user.friends
    @query = normalize(query)
    @query_tokens = @query.split
    @sort = SORTS.key?(sort.to_s) ? sort.to_s : DEFAULT_SORT
  end

  def call
    return friends.order(SORTS.fetch(sort)).to_a if query.blank?

    ranked_friend_ids = friends.order(SORTS.fetch(sort)).pluck(:id, :name)
      .each_with_index
      .filter_map do |(id, name), sort_position|
        normalized_name = normalize(name)
        candidate_score = score(normalized_name, normalized_name.split)
        [ id, candidate_score, sort_position ] if candidate_score
      end
      .sort_by { |id, candidate_score, sort_position| [ -candidate_score, sort_position ] }
      .first(Rails.application.config.x.friend_search_max_results)
      .map(&:first)

    return [] if ranked_friend_ids.empty?

    friends_by_id = friends.where(id: ranked_friend_ids).index_by(&:id)
    ranked_friend_ids.filter_map { |id| friends_by_id[id] }
  end

  private

  attr_reader :friends, :query, :query_tokens, :sort

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

  def normalize(value)
    value.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip.gsub(/\s+/, " ")
  end
end
