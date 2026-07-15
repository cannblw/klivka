class ConfirmationsMailer < ApplicationMailer
  def confirm(user)
    @user = user
    mail to: user.email_address
  end
end
