class ConfirmationsMailerPreview < ActionMailer::Preview
  def confirm
    ConfirmationsMailer.confirm(preview_user(:en))
  end

  def confirm_spanish
    ConfirmationsMailer.confirm(preview_user(:es))
  end

  private

  def preview_user(locale)
    User.take!.tap { |user| user.locale = locale.to_s }
  end
end
