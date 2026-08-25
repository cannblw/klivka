require "test_helper"

class ConfirmationsMailerTest < ActionMailer::TestCase
  test "confirmation email uses the branded multipart layout and confirmation link" do
    user = users(:one)

    mail = ConfirmationsMailer.confirm(user)

    assert_predicate mail, :multipart?
    assert_equal [ user.email_address ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_includes mail.html_part.body.to_s, 'src="http://localhost:3000/brand/klivka-logo.svg"'
    action_url = Nokogiri::HTML(mail.html_part.body.to_s).at_css(".email-card-content a")["href"]
    assert_match %r{/confirmation/}, action_url
    assert_includes mail.text_part.body.to_s, action_url
  end

  test "confirmation email marks the document with the account locale" do
    user = users(:one)
    user.locale = "es"

    mail = ConfirmationsMailer.confirm(user)

    assert_equal "es", Nokogiri::HTML(mail.html_part.body.to_s).at_css("html")["lang"]
    assert_predicate mail.text_part.body.to_s, :present?
  end
end
