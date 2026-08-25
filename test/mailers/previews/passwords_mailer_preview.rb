class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    PasswordsMailer.reset(preview_user(:en))
  end

  def reset_spanish
    PasswordsMailer.reset(preview_user(:es))
  end

  private

  def preview_user(locale)
    User.take!.tap { |user| user.locale = locale.to_s }
  end
end
