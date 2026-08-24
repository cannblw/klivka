class VcardImportCandidateComponent < ViewComponent::Base
  with_collection_parameter :candidate

  def initialize(candidate:, selected_candidate_ids: [])
    @candidate = candidate
    @selected = selected_candidate_ids.include?(candidate.fetch("id"))
  end

  private

  attr_reader :candidate, :selected

  def candidate_id
    candidate.fetch("id")
  end

  def checkbox_id
    "vcard-import-candidate-#{candidate_id}"
  end

  def details_id
    "#{checkbox_id}-details"
  end

  def name
    candidate.fetch("name")
  end

  def details
    @details ||= candidate.fetch("entries").filter_map do |entry|
      label, value = detail_for(entry)
      "#{label}: #{value}" if value.present?
    end
  end

  def search_value
    contact_values = candidate.fetch("entries").filter_map do |entry|
      entry.dig("content", "number") || entry.dig("content", "email")
    end
    [ name, *contact_values ].join(" ")
  end

  def detail_for(entry)
    case entry.fetch("type")
    when Entry::Phone.name
      [ t("entries.kinds.phone"), contact_value(entry) ]
    when Entry::Email.name
      [ t("entries.kinds.email"), contact_value(entry) ]
    when Entry::Birthday.name
      [ t("entries.kinds.birthday"), localized_date(entry.fetch("entry_date")) ]
    when Entry::Date.name
      [ entry.dig("content", "label").presence || t("entries.kinds.date"), localized_date(entry.fetch("entry_date")) ]
    when Entry::Note.name
      [ t("entries.kinds.note"), entry.dig("content", "text") ]
    end
  end

  def contact_value(entry)
    [ entry.dig("content", "label").presence, entry.dig("content", "number") || entry.dig("content", "email") ].compact.join(": ")
  end

  def localized_date(date)
    I18n.l(Date.iso8601(date), format: :long)
  end
end
