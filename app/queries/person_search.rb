class PersonSearch
  MATCH_SCORE_PERCENTAGES = { exact: 100, name_prefix: 90, token_prefix: 85, substring: 80, initials: 75, fuzzy: 70 }.freeze
  MINIMUM_FUZZY_QUERY_LENGTH = 2
  TWO_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.85
  THREE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.78
  FOUR_OR_MORE_CHARACTER_FUZZY_SIMILARITY_THRESHOLD = 0.65

  def initialize(query)
    @query = PersonNameNormalizer.call(query)
    @query_tokens = @query.split
  end

  def call(people)
    return people if query.blank?

    people.each_with_index.filter_map { |person, position| ranked_match(person, position) }
      .sort_by { |_, score, position| [ -score, position ] }
      .first(Rails.application.config.x.person_search_max_results).map(&:first)
  end

  private

  attr_reader :query, :query_tokens

  def ranked_match(person, position)
    normalized_name = PersonNameNormalizer.call(person.name)
    score = score(normalized_name, normalized_name.split)
    [ person, score, position ] if score
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
