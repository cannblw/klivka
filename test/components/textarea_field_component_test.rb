require "test_helper"

class TextareaFieldComponentTest < ViewComponent::TestCase
  class FakeForm
    def object; end

    def text_area(field, **options)
      attrs = options.map do |key, value|
        case value
        when true then key.to_s
        else "#{key}='#{value}'"
        end
      end.join(" ")
      "<textarea name='#{field}' #{attrs}></textarea>".html_safe
    end
  end

  test "renders a textarea with shared styling classes" do
    render_inline TextareaFieldComponent.new(FakeForm.new, :note, rows: 3, placeholder: "Write here")

    assert_selector "textarea[name='note'][rows='3'][placeholder='Write here']"
    assert_selector "[class*='rounded-lg'][class*='border-stone-300'][class*='resize-none']"
  end

  test "appends extra classes" do
    render_inline TextareaFieldComponent.new(FakeForm.new, :note, class: "mt-1")

    assert_selector "textarea[class*='mt-1'][class*='rounded-lg']"
  end
end
