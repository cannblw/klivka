class VcardImport::Importer
  def self.call(vcard_import:, selected_candidate_ids:)
    new(vcard_import:, selected_candidate_ids:).call
  end

  def initialize(vcard_import:, selected_candidate_ids:)
    @vcard_import = vcard_import
    @selected_candidate_ids = selected_candidate_ids
  end

  def call
    vcard_import.user.with_lock do
      vcard_import.lock!
      vcard_import.assign_attributes(selected_candidate_ids:)
      vcard_import.save!(context: :import)

      selected_candidates.each { |candidate| import_candidate(candidate) }
      vcard_import.destroy!
    end
  end

  private

  attr_reader :vcard_import, :selected_candidate_ids

  def selected_candidates
    selected_ids = selected_candidate_ids.index_with(true)
    vcard_import.candidates.select { |candidate| selected_ids.key?(candidate.fetch("id")) }
  end

  def import_candidate(candidate)
    friend = vcard_import.user.friends.create!(name: candidate.fetch("name"))

    candidate.fetch("entries").each_with_index do |entry, position|
      attributes = entry.slice("type", "content", "entry_date", "birthday_year_known")
      friend.entries.create!(attributes.merge("position" => position))
    end
  end
end
