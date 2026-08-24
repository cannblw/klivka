class VcardImport::Parser
  Result = Data.define(:candidates, :rejected_count)
  CARD_START_PATTERN = /^BEGIN:VCARD[ \t]*$/i
  CARD_END_PATTERN = /^END:VCARD[ \t]*$/i
  CARD_BOUNDARY_PATTERN = /(?=^BEGIN:VCARD[ \t]*$)/i
  EMPTY_FIELDS = [].freeze
  UTF_8_BOM = "\xEF\xBB\xBF".b
  UTF_16_BOMS = [ "\xFF\xFE".b, "\xFE\xFF".b ].freeze
  PROPERTY_MULTIPLICITY = {
    tel: :repeated,
    email: :repeated,
    bday: :single,
    anniversary: :single,
    note: :repeated
  }.freeze
  SUPPORTED_PROPERTIES = PROPERTY_MULTIPLICITY.keys.freeze
  SUPPORTED_FIELD_NAMES = SUPPORTED_PROPERTIES.map { |property| property.to_s.upcase }.freeze
  CARD_METADATA_FIELD_NAMES = %w[BEGIN END VERSION FN N PRODID UID REV KIND].freeze
  IGNORED_FIELD_NAMES = (SUPPORTED_FIELD_NAMES + CARD_METADATA_FIELD_NAMES).freeze

  def initialize(source, max_cards: Rails.application.config.x.vcard_import_max_cards)
    @source = normalize_encoding(source)
    @max_cards = max_cards
  end

  def call
    cards = card_segments
    raise TooManyCardsError if cards.size > @max_cards

    candidates = []
    rejected_count = 0

    cards.each_with_index do |card_source, id|
      candidate = parse_card(card_source, id) if complete_card?(card_source)
      candidate ? candidates << candidate : rejected_count += 1
    end

    Rails.logger.info("vCard import rejected: #{rejected_count} malformed cards") if rejected_count.positive?

    Result.new(candidates:, rejected_count:)
  end

  class TooManyCardsError < StandardError; end
  class InvalidEncodingError < StandardError; end

  private

  def normalize_encoding(source)
    bytes = source.to_s.b
    # Segmenting cards before library decoding requires one predictable encoding for boundary matching.
    encoding = bytes.start_with?(*UTF_16_BOMS) ? Encoding::UTF_16 : Encoding::UTF_8
    normalized = bytes.delete_prefix(UTF_8_BOM).force_encoding(encoding).encode(Encoding::UTF_8)

    raise InvalidEncodingError unless normalized.valid_encoding?

    normalized.gsub("\r\n", "\n").tr("\r", "\n")
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    raise InvalidEncodingError
  end

  def card_segments
    @source.split(CARD_BOUNDARY_PATTERN).filter_map do |segment|
      next unless segment.match?(CARD_START_PATTERN)

      ending = segment.match(CARD_END_PATTERN)
      ending ? segment[..ending.end(0)] : segment
    end
  end

  def complete_card?(source)
    source.match?(CARD_END_PATTERN)
  end

  def parse_card(source, id)
    card = Vcard::Vcard.decode(source).first
    return unless card

    fields = card.fields.group_by(&:name)
    name = full_name(fields)
    return if name.blank?

    candidate = {
      "id" => id,
      "name" => name,
      "entries" => entries_for(fields)
    }
    unsupported_properties = unsupported_properties(fields)
    candidate["unsupported_properties"] = unsupported_properties if unsupported_properties.any?
    candidate
  rescue Vcard::InvalidEncodingError
    nil
  end

  def full_name(fields)
    field_value(fields, "FN").presence || name_from_structured_field(fields)
  end

  def name_from_structured_field(fields)
    field = fields.fetch("N", EMPTY_FIELDS).first
    return unless field

    family, given, additional, prefix, suffix = Vcard.decode_text_list(field.value_raw, ";")
    [ prefix, given, additional, family, suffix ].compact_blank.join(" ").presence
  end

  def entries_for(fields)
    PROPERTY_MULTIPLICITY.flat_map do |property, multiplicity|
      case multiplicity
      when :repeated then repeated_entries(fields, property)
      when :single then single_date_entry(fields, property)
      end
    end
  end

  def unsupported_properties(fields)
    fields.filter_map do |field_name, fields_for_name|
      next if IGNORED_FIELD_NAMES.include?(field_name)

      field_name if fields_for_name.any? { |field| field.value_raw.to_s.strip.present? }
    end
  end

  def repeated_entries(fields, property)
    fields.fetch(property.to_s.upcase, EMPTY_FIELDS).filter_map do |field|
      VcardImport::EntryMapping.build(property:, value: decoded_value(field), label: label_for(field))
    end
  end

  def single_date_entry(fields, property)
    field = fields.fetch(property.to_s.upcase, EMPTY_FIELDS).first
    return [] unless field

    [ VcardImport::EntryMapping.build(property:, value: decoded_value(field)) ].compact
  end

  def field_value(fields, name)
    field = fields.fetch(name, EMPTY_FIELDS).first
    field && decoded_value(field)
  end

  def decoded_value(field)
    Vcard.decode_text(field.value.to_s).strip
  end

  def label_for(field)
    field.pvalues("TYPE")&.filter_map { |type| type.to_s.strip.downcase.presence }&.uniq&.join(", ")&.presence
  end
end
