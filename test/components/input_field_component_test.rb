require "test_helper"

class InputFieldComponentTest < ViewComponent::TestCase
  class FakeForm
    def object; end

    def email_field(field, **options)
      tag(:email, options)
    end

    def password_field(field, **options)
      tag(:password, options)
    end

    def search_field(field, **options)
      tag(:search, options)
    end

    def number_field(field, **options)
      tag(:number, options)
    end

    def date_field(field, **options)
      tag(:date, options)
    end

    def text_field(field, **options)
      tag(:text, options)
    end

    private

    def tag(type, options)
      attrs = options.map do |k, v|
        case v
        when true then k.to_s
        else "#{k}='#{v}'"
        end
      end.join(" ")
      "<input type='#{type}' #{attrs} />".html_safe
    end
  end

  test "renders an email field with passed-through options and shared classes" do
    render_inline InputFieldComponent.new(FakeForm.new, :email_address, type: :email,
      required: true, placeholder: "Email")

    assert_selector "input[type='email'][required][placeholder='Email']"
    assert_selector "[class*='rounded-lg'][class*='border-stone-300']"
  end

  test "renders a password field" do
    render_inline InputFieldComponent.new(FakeForm.new, :password, type: :password,
      maxlength: 72)

    assert_selector "input[type='password'][maxlength='72']"
  end

  test "renders a search field" do
    render_inline InputFieldComponent.new(FakeForm.new, :query, type: :search,
      placeholder: "Search")

    assert_selector "input[type='search'][placeholder='Search']"
  end

  test "renders a number field" do
    render_inline InputFieldComponent.new(FakeForm.new, :lead_value, type: :number,
      min: 0, step: 1)

    assert_selector "input[type='number'][min='0'][step='1']"
  end

  test "renders a date field" do
    render_inline InputFieldComponent.new(FakeForm.new, :entry_date, type: :date,
      data: { action: "change->reminder-date#update" })

    assert_selector "input[type='date']"
  end

  test "appends extra classes" do
    render_inline InputFieldComponent.new(FakeForm.new, :name, type: :text,
      class: "w-full")

    assert_selector "input[type='text'][class*='w-full']"
  end
end
