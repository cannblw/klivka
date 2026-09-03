class AccountImportsController < ApplicationController
  unavailable_in_demo_mode

  rate_limit to: Rails.application.config.x.account_import_upload_rate_limit,
    within: Rails.application.config.x.account_import_upload_rate_window,
    by: -> { Current.user.id },
    only: :create,
    scope: :account_import_uploads,
    with: :respond_to_upload_rate_limit

  def create
    uploaded_file = params.dig(:account_import, :file)
    return respond_with_error(:missing_file) unless uploaded_file.respond_to?(:read) && uploaded_file.respond_to?(:size)
    return respond_with_error(:file_too_large, size: helpers.number_to_human_size(max_file_size)) if uploaded_file.size > max_file_size
    return respond_with_error(:invalid_password) unless Current.user.authenticate(params.dig(:account_import, :password))

    document = AccountImport::Document.parse(uploaded_file.read)
    AccountImport::Importer.call(user: Current.user, document:)
    ReminderScanJob.perform_later(Current.user.id)

    respond_with_success
  rescue AccountImport::Document::InvalidDocument => error
    respond_with_error(error.code)
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.warn("Account import could not restore #{error.record.class.name}")
    respond_with_error(:invalid_file)
  end

  private

  def max_file_size
    Rails.application.config.x.account_import_max_file_size_bytes
  end

  def respond_with_success
    message = I18n.t("account_imports.success", locale: Current.user.locale.presence || I18n.default_locale)

    respond_to do |format|
      format.json do
        flash[:notice] = message
        render json: { success: true, redirect_url: settings_path }
      end
      format.html { redirect_to settings_path, notice: message }
    end
  end

  def respond_with_error(error, **options)
    message = t("account_imports.errors.#{error}", **options)

    respond_to do |format|
      format.json do
        render json: { success: false, code: error, error: message }, status: :unprocessable_entity
      end
      format.html { redirect_to settings_path, alert: message, status: :see_other }
    end
  end

  def respond_to_upload_rate_limit
    respond_with_error(:rate_limited)
  end
end
