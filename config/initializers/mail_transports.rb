Rails.application.config.to_prepare do
  MailTransports.register :rails, MailTransports::RailsAdapter.new
  MailTransports.register :resend, MailTransports::ResendAdapter.new
  MailTransports.fetch(Rails.application.config.x.reminder_mail_transport)
end
