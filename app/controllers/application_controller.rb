class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  private

  def switch_locale(&action)
    I18n.with_locale(preferred_locale, &action)
  end

  # Header order approximates preference; full q-value parsing isn't worth a dependency
  def preferred_locale
    requested = request.env["HTTP_ACCEPT_LANGUAGE"].to_s.split(",").map { |lang| lang.strip[0, 2].downcase }
    requested.find { |code| code.in?(I18n.available_locales.map(&:to_s)) } || I18n.default_locale
  end
end
