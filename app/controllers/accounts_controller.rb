class AccountsController < ApplicationController
  unavailable_in_demo_mode

  def destroy
    user = Current.user
    unless user.authenticate(params.dig(:account, :password))
      @user = user
      @account_deletion_error = t("account_deletions.invalid_password")
      return render "settings/show", status: :unprocessable_entity
    end

    locale = I18n.locale
    AccountDeletion::Destroy.call(user:)
    forget_session
    redirect_to new_session_path, notice: I18n.t("account_deletions.destroyed", locale:)
  end
end
