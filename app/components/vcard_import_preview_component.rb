class VcardImportPreviewComponent < ViewComponent::Base
  def initialize(vcard_import:)
    @vcard_import = vcard_import
  end

  private

  attr_reader :vcard_import

  def selected_candidate_ids
    @selected_candidate_ids ||= vcard_import.selected_candidate_ids.to_set
  end

  def selected_count
    @selected_count ||= vcard_import.candidates.count do |candidate|
      selected_candidate_ids.include?(candidate.fetch("id"))
    end
  end

  def selection_required?
    selected_count.zero?
  end

  def all_selected?
    selected_count == vcard_import.candidates.size
  end
end
