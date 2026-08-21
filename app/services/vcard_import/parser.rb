class VcardImport::Parser
  Result = Data.define(:candidates, :rejected_count)
  CARD_START_PATTERN = /^BEGIN:VCARD[ \t]*$/i
  CARD_END_PATTERN = /^END:VCARD[ \t]*$/i
  CARD_BOUNDARY_PATTERN = /(?=^BEGIN:VCARD[ \t]*$)/i
  EMPTY_FIELDS = [].freeze
  UTF_8_BOM = "\xEF\xBB\xBF".b
  UTF_16_BOMS = [ "\xFF\xFE".b, "\xFE\xFF".b ].freeze

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

    { "id" => id, "name" => name, "entries" => entries_for(fields) }
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
    repeated_entries(fields, "TEL", Entry::Phone.vcard_import_property) +
      repeated_entries(fields, "EMAIL", Entry::Email.vcard_import_property) +
      single_date_entry(fields, "BDAY", Entry::Birthday.vcard_import_property) +
      single_date_entry(fields, "ANNIVERSARY", Entry::Date.vcard_import_property) +
      repeated_entries(fields, "NOTE", Entry::Note.vcard_import_property)
  end

  def repeated_entries(fields, field_name, property)
    fields.fetch(field_name, EMPTY_FIELDS).filter_map do |field|
      VcardImport::EntryMapping.build(property:, value: decoded_value(field), label: label_for(field))
    end
  end

  def single_date_entry(fields, field_name, property)
    field = fields.fetch(field_name, EMPTY_FIELDS).first
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
