require "test_helper"

class DemoModeTest < ActionDispatch::IntegrationTest
  test "signs each visitor into the shared demo account" do
    with_demo_mode do |demo_user|
      get root_path

      assert_response :success
      assert_equal demo_user, Session.order(:created_at).last.user
      assert_equal DemoMode::DEMO_SESSION_USER_AGENT, Session.order(:created_at).last.user_agent
      assert_select "main", /People/
    end
  end

  test "records visitor activity before serving the demo" do
    travel_to Time.utc(2026, 8, 19, 12) do
      with_demo_mode do
        state = DemoState.current(at: 1.hour.ago)

        get root_path

        assert_equal Time.current, state.reload.last_activity_at
      end
    end
  end

  test "reuses one authentication record across demo visitors" do
    with_demo_mode do |demo_user|
      get root_path
      demo_session = demo_user.sessions.find_by!(user_agent: DemoMode::DEMO_SESSION_USER_AGENT)
      cookies.delete(:session_id)

      assert_no_difference "Session.count" do
        get root_path
      end

      assert_equal demo_session, demo_user.sessions.find_by!(user_agent: DemoMode::DEMO_SESSION_USER_AGENT)
    end
  end

  test "replaces a session belonging to another account" do
    other_user = users(:one)
    sign_in_as other_user
    other_session = other_user.sessions.order(:created_at).last

    with_demo_mode do |demo_user|
      get root_path

      assert_response :success
      assert_not Session.exists?(other_session.id)
      assert_equal demo_user, Session.order(:created_at).last.user
    end
  end

  test "marks demo pages as shared and unavailable to search engines" do
    with_demo_mode do
      get root_path

      assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
      assert_select "meta[name='robots'][content='noindex, nofollow']", visible: :all
      assert_select "aside[role='status']", text: /shared demo/
      assert_select "form[action='#{session_path}']", count: 0
    end
  end

  test "does not show password management in demo settings" do
    with_demo_mode do
      get settings_path

      assert_response :success
      assert_select "a[href='#{new_password_path}']", count: 0
    end
  end

  test "keeps the shared demo in English" do
    with_demo_mode do |demo_user|
      demo_user.update!(locale: "es")

      get settings_path, headers: { "Accept-Language" => "es-ES,es;q=0.9" }

      assert_response :success
      assert_select "html[lang=en]"
      assert_select "input[name='user[locale]'][value='en'][disabled]", count: 1
      assert_select "input[name='user[locale]'][value='es'][disabled]", count: 1
      assert_select "#language-switch-disabled", text: I18n.t("settings.show.language_switch_disabled"), count: 1
    end
  end

  test "ignores locale changes submitted to shared demo settings" do
    with_demo_mode do |demo_user|
      patch settings_path, params: { user: { locale: "es" } }

      assert_redirected_to settings_url
      assert_nil demo_user.reload.locale
      follow_redirect!
      assert_select "html[lang=en]"
    end
  end

  test "redirects account and credential pages to the demo" do
    with_demo_mode do
      [ new_session_path, signup_path, new_password_path, edit_password_path("unused"), confirmation_path("unused") ].each do |path|
        get path

        assert_redirected_to root_path
      end
    end
  end

  test "prevents account and credential mutations" do
    with_demo_mode do |demo_user|
      assert_no_difference "User.count" do
        post signup_path, params: { user: { email_address: "visitor@example.com", password: "a-safe-password" } }
      end

      assert_no_enqueued_emails do
        post passwords_path, params: { email_address: demo_user.email_address }
      end

      original_password_digest = demo_user.password_digest
      put password_path(demo_user.password_reset_token), params: {
        password: "another-safe-password",
        password_confirmation: "another-safe-password"
      }
      assert_equal original_password_digest, demo_user.reload.password_digest

      delete session_path
      assert_redirected_to root_path
    end
  end

  test "limits mutations across controllers for each visitor address" do
    with_demo_mode do
      Rails.application.config.x.demo_mutation_rate_limit.times do
        post signup_path
        assert_redirected_to root_path
      end

      post signup_path
      follow_redirect!

      assert_select "#flash", text: /shared demo limits how many changes/
    end
  end

  test "does not add demo presentation outside demo mode" do
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_nil response.headers["X-Robots-Tag"]
    assert_select "meta[name='robots']", count: 0
    assert_select "aside[role='status']", count: 0
    assert_select "form[action='#{session_path}']", count: 1
  end
end
