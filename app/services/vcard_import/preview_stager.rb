class VcardImport::PreviewStager
  def self.call(user:, candidates:, rejected_count:)
    user.with_lock do
      user.vcard_imports.destroy_all
      vcard_import = user.vcard_imports.create!(
        candidates:,
        rejected_count:,
        selected_candidate_ids: candidates.pluck("id")
      )
      VcardImportExpirationJob.set(wait_until: vcard_import.expires_at).perform_later(vcard_import.id)
      vcard_import
    end
  end
end
