class ConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    if user = User.find_by_token_for(:email_confirmation, params[:token])
      user.confirm!
      redirect_to new_session_path, notice: t(".confirmed")
    else
      redirect_to new_session_path, alert: t(".invalid_token")
    end
  end
end
