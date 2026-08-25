require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "password reset email uses the branded multipart layout and reset link" do
    user = users(:one)

    mail = PasswordsMailer.reset(user)

    assert_predicate mail, :multipart?
    assert_equal [ user.email_address ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_includes mail.html_part.body.to_s, 'src="http://localhost:3000/brand/klivka-logo.svg"'
    action_url = Nokogiri::HTML(mail.html_part.body.to_s).at_css(".email-card-content a")["href"]
    assert_match %r{/passwords/.+/edit}, action_url
    assert_includes mail.text_part.body.to_s, action_url
  end

  test "password reset email marks the document with the account locale" do
    user = users(:one)
    user.locale = "es"

    mail = PasswordsMailer.reset(user)

    assert_equal "es", Nokogiri::HTML(mail.html_part.body.to_s).at_css("html")["lang"]
    assert_predicate mail.text_part.body.to_s, :present?
  end
end
