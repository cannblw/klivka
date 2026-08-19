class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.config.x.mail_from }
  layout "mailer"

  application_uri = URI.parse(Rails.application.config.x.application_url)
  self.default_url_options = { host: application_uri.host, protocol: application_uri.scheme }
  default_url_options[:port] = application_uri.port unless application_uri.port == application_uri.class.default_port
  default_url_options[:script_name] = application_uri.path if application_uri.path.present? && application_uri.path != "/"
end
