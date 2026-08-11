module DemoMode
  extend ActiveSupport::Concern

  DEMO_SESSION_USER_AGENT = "Klivka shared demo".freeze

  included do
    prepend_before_action :start_demo_session, if: :demo_mode?
    before_action :record_demo_activity, if: :demo_mode?
    after_action :disallow_demo_indexing, if: :demo_mode?
    helper_method :demo_mode?
  end

  class_methods do
    def unavailable_in_demo_mode(**options)
      before_action :redirect_from_demo_account_flow, if: :demo_mode?, **options
    end
  end

  private

  def demo_mode?
    Rails.application.config.x.demo_mode
  end

  def demo_mutation_request?
    demo_mode? && request.request_method_symbol.in?(%i[post put patch delete])
  end

  def start_demo_session
    demo_user = User.find_by!(email_address: Rails.application.config.x.demo_user_email_address)
    return if resume_session&.user_id == demo_user.id

    terminate_session if Current.session
    use_session demo_user.sessions.find_or_create_by!(user_agent: DEMO_SESSION_USER_AGENT, ip_address: nil)
  end

  def disallow_demo_indexing
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end

  def record_demo_activity
    DemoState.current.record_activity!
  end

  def redirect_from_demo_account_flow
    redirect_to root_path, notice: t("demo.account_management_unavailable"), status: :see_other
  end

  def respond_to_demo_rate_limit
    redirect_back_or_to root_path, alert: t("demo.rate_limited"), status: :see_other
  end
end
