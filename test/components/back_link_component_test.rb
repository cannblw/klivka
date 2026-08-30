require "test_helper"

class BackLinkComponentTest < ViewComponent::TestCase
  test "renders a stable fallback with history enhancement" do
    render_inline BackLinkComponent.new(fallback_path: "/people")

    assert_link "Back", href: "/people"
    assert_selector "a[data-controller='history-back'][data-action='click->history-back#navigate']"
    assert_selector ".material-icons[aria-hidden='true']", text: "arrow_back"
  end

  test "localizes the visible label" do
    I18n.with_locale(:es) do
      render_inline BackLinkComponent.new(fallback_path: "/people")

      assert_link "Volver", href: "/people"
    end
  end
end
