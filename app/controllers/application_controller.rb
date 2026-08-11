class ApplicationController < ActionController::Base
  include Authentication
  include DemoMode

  rate_limit to: Rails.application.config.x.demo_mutation_rate_limit,
    within: Rails.application.config.x.demo_mutation_rate_window,
    by: -> { request.remote_ip },
    with: :respond_to_demo_rate_limit,
    scope: :demo_mutations,
    if: :demo_mutation_request?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale
  around_action :switch_time_zone

  private

  def switch_locale(&action)
    I18n.with_locale(preferred_locale, &action)
  end

  def switch_time_zone(&action)
    Time.use_zone(preferred_time_zone, &action)
  end

  # Header order approximates preference; full q-value parsing isn't worth a dependency
  def preferred_locale
    Current.user&.locale&.presence ||
      requested_locale_from_header ||
      I18n.default_locale
  end

  def preferred_time_zone
    Current.user&.time_zone || Rails.application.config.x.default_time_zone
  end

  def requested_locale_from_header
    request.env["HTTP_ACCEPT_LANGUAGE"].to_s.split(",").map { |lang| lang.strip[0, 2].downcase }
      .find { |code| code.in?(I18n.available_locales.map(&:to_s)) }
  end
end
