class AccountImportPreviewsController < ApplicationController
  unavailable_in_demo_mode

  rate_limit to: Rails.application.config.x.account_import_upload_rate_limit,
    within: Rails.application.config.x.account_import_upload_rate_window,
    by: -> { Current.user.id },
    only: :create,
    scope: :account_import_uploads,
    with: :respond_to_upload_rate_limit

  def create
    uploaded_file = params.dig(:account_import, :file)
    return render_error(:missing_file) unless uploaded_file.respond_to?(:read) && uploaded_file.respond_to?(:size)
    return render_error(:file_too_large, size: helpers.number_to_human_size(max_file_size)) if uploaded_file.size > max_file_size

    document = AccountImport::Document.parse(uploaded_file.read)

    response.headers["Cache-Control"] = "no-store"
    render json: { valid: true, summary: document.summary }
  rescue AccountImport::Document::InvalidDocument
    render_error(:invalid_file)
  end

  private

  def max_file_size
    Rails.application.config.x.account_import_max_file_size_bytes
  end

  def render_error(error, **options)
    response.headers["Cache-Control"] = "no-store"
    render json: { valid: false, error: t("account_imports.errors.#{error}", **options) },
      status: :unprocessable_entity
  end

  def respond_to_upload_rate_limit
    response.headers["Cache-Control"] = "no-store"
    render json: { valid: false, error: t("account_imports.errors.rate_limited") }, status: :too_many_requests
  end
end
