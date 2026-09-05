require "test_helper"
require "axe/matchers/be_axe_clean"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  AXE_WCAG_TAGS = %i[wcag2a wcag2aa wcag21a wcag21aa wcag22a wcag22aa].freeze

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  private

  def assert_accessible_page
    duplicate_ids = page.all("[id]", visible: :all)
      .filter_map { |element| element[:id].presence }
      .tally
      .select { |_id, count| count > 1 }
    assert_empty duplicate_ids, "Duplicate DOM IDs: #{duplicate_ids.keys.sort.join(", ")}"

    matcher = Axe::Matchers.be_axe_clean.according_to(AXE_WCAG_TAGS)
    assert matcher.matches?(page), matcher.failure_message
  end

  def sign_in_as(user)
    session = user.sessions.create!
    cookie_jar = ActionDispatch::TestRequest.create.cookie_jar
    cookie_jar.signed[:session_id] = session.id

    visit new_session_path
    page.driver.browser.manage.add_cookie(name: "session_id", value: cookie_jar[:session_id])
    visit root_path
    assert_current_path root_path
  end
end
