class FileFieldComponent < ViewComponent::Base
  def initialize(form:, field:, label:, hint:, choose_label:, empty_label:, accept: nil)
    @form = form
    @field = field
    @label = label
    @hint = hint
    @choose_label = choose_label
    @empty_label = empty_label
    @accept = accept
  end

  private

  attr_reader :form, :field, :label, :hint, :choose_label, :empty_label, :accept

  def field_id
    form.field_id(field)
  end

  def hint_id
    "#{field_id}-hint"
  end

  def filename_id
    "#{field_id}-filename"
  end
end
