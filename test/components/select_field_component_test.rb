require "test_helper"

class SelectFieldComponentTest < ViewComponent::TestCase
  class FakeForm
    attr_reader :field, :choices, :select_options, :html_options

    def select(field, choices, options, html_options)
      @field = field
      @choices = choices
      @select_options = options
      @html_options = html_options
      tag(:select, html_options.merge(name: field, data: choices.inspect))
    end

    private

    def tag(type, options)
      attrs = options.map do |key, value|
        "#{key}='#{value}'"
      end.join(" ")
      "<#{type} #{attrs}></#{type}>".html_safe
    end
  end

  test "renders a select with passed-through options and shared classes" do
    form = FakeForm.new
    choices = [ [ "Name", "" ], [ "Recently added", "recently_added" ] ]

    render_inline SelectFieldComponent.new(form, :sort,
      choices: choices,
      selected: "recently_added",
      select_options: { include_blank: "Choose a sort order" },
      wrapper_class: "mt-1",
      aria: { label: "Sort friends" })

    assert_selector "div.relative.mt-1 > select[name='sort']"
    assert_selector "select[class*='appearance-none'][class*='pr-10'][class*='rounded-lg'][class*='border-stone-300']"
    assert_selector "span[aria-hidden='true'] > .material-icons", text: "expand_more"
    assert_equal :sort, form.field
    assert_equal choices, form.choices
    assert_equal({ selected: "recently_added", include_blank: "Choose a sort order" }, form.select_options)
    assert_equal({ label: "Sort friends" }, form.html_options[:aria])
  end
end
