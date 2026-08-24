class VcardImportExpirationJob < ApplicationJob
  queue_as :background

  def perform(vcard_import_id)
    vcard_import = VcardImport.find_by(id: vcard_import_id)
    vcard_import&.destroy! if vcard_import&.expired?
  end
end
