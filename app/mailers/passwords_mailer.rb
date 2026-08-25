class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @password_reset_url = edit_password_url(user.password_reset_token)
    I18n.with_locale(user.locale.presence || I18n.default_locale) do
      mail to: user.email_address
    end
  end
end
