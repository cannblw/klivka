class ConfirmationsMailer < ApplicationMailer
  def confirm(user)
    @user = user
    @confirmation_url = confirmation_url(user.generate_token_for(:email_confirmation))
    I18n.with_locale(user.locale.presence || I18n.default_locale) do
      mail to: user.email_address
    end
  end
end
