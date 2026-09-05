class VcardImport::EntryMapping
  def self.build(property:, value:, label: nil)
    entry_type = Entry.vcard_importable_type_for(property)

    case
    when entry_type == Entry::Phone
      number = normalize_phone(value)
      entry(entry_type.name, content: { "number" => number, "label" => label }) if number
    when entry_type == Entry::Email
      email = value.to_s.strip.downcase
      entry(entry_type.name, content: { "email" => email, "label" => label }) if email.match?(URI::MailTo::EMAIL_REGEXP)
    when entry_type == Entry::Birthday
      birthday_attributes(value)&.then { |attributes| entry(entry_type.name, **attributes) }
    when entry_type == Entry::Date
      date = parse_full_date(value)
      entry(entry_type.name, entry_date: date.iso8601, content: { "label" => I18n.t("vcard_import.anniversary") }) if date
    when entry_type == Entry::Note
      text = value.to_s.strip.presence
      entry(entry_type.name, content: { "text" => text }) if text
    end
  end

  def self.entry(type, **attributes)
    attributes.stringify_keys.merge("type" => type)
  end
  private_class_method :entry

  def self.normalize_phone(value)
    value.to_s.strip.sub(/\Atel:/i, "").presence
  end
  private_class_method :normalize_phone

  def self.parse_full_date(value)
    normalized_value = value.to_s
    return unless normalized_value.match?(/\A\d{4}-?\d{2}-?\d{2}\z/)

    Date.iso8601(normalized_value)
  rescue Date::Error
    nil
  end
  private_class_method :parse_full_date

  def self.birthday_attributes(value)
    date = parse_full_date(value)
    return { entry_date: date.iso8601 } if date

    match = value.to_s.match(/\A--(\d{2})-?(\d{2})\z/)
    return unless match

    date = Date.new(Entry::Birthday::UNKNOWN_YEAR_ANCHOR, Integer(match[1], 10), Integer(match[2], 10))
    { entry_date: date.iso8601, birthday_year_known: false }
  rescue ArgumentError
    nil
  end
  private_class_method :birthday_attributes
end
