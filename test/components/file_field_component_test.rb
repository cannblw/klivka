require "test_helper"

class FileFieldComponentTest < ViewComponent::TestCase
  test "file field component renders an accessible custom file chooser" do
    vcard_import = VcardImport.new
    form = ActionView::Helpers::FormBuilder.new(:vcard_import, vcard_import, vc_test_controller.view_context, {})

    render_inline FileFieldComponent.new(
      form:,
      field: :file,
      label: "vCard file",
      hint: "Choose a file up to 5 MB.",
      choose_label: "Choose a vCard",
      empty_label: "No vCard selected.",
      accept: ".vcf,text/vcard"
    )

    assert_selector "[data-controller='file-field'][data-file-field-empty-name-value='No vCard selected.']"
    assert_selector "label[for='vcard_import_file']", text: "vCard file"
    assert_selector "input#vcard_import_file[type='file'][accept='.vcf,text/vcard'][aria-describedby='vcard_import_file-hint vcard_import_file-filename'][data-action='change->file-field#update']"
    assert_selector "label[for='vcard_import_file']", text: "Choose a vCard"
    assert_selector "#vcard_import_file-filename[aria-live='polite'][data-file-field-target='name']", text: "No vCard selected."
  end
end
