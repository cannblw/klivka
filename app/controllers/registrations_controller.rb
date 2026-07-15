class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to signup_path, alert: t("auth.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      if Rails.application.config.x.require_email_confirmation
        ConfirmationsMailer.confirm(@user).deliver_later
        redirect_to new_session_path, notice: t(".check_email")
      else
        start_new_session_for @user
        redirect_to root_path, notice: t(".created")
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password ])
  end
end
