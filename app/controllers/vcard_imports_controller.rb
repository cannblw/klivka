class VcardImportsController < ApplicationController
  unavailable_in_demo_mode

  rate_limit to: Rails.application.config.x.vcard_import_upload_rate_limit,
    within: Rails.application.config.x.vcard_import_upload_rate_window,
    by: -> { Current.user.id },
    only: :create,
    scope: :vcard_import_uploads,
    with: :respond_to_upload_rate_limit

  before_action :set_vcard_import, only: %i[ show update ]

  def new
    @vcard_import = VcardImport.new
  end

  def create
    uploaded_file = params.dig(:vcard_import, :file)
    return render_upload_error(:missing_file) unless uploaded_file.respond_to?(:read) && uploaded_file.respond_to?(:size)
    return render_upload_error(:file_too_large) if uploaded_file.size > max_file_size

    result = VcardImport::Parser.new(uploaded_file.read).call
    return render_upload_error(:no_people_found) if result.candidates.empty?

    vcard_import = VcardImport::PreviewStager.call(
      user: Current.user,
      candidates: result.candidates,
      rejected_count: result.rejected_count
    )

    redirect_to vcard_import
  rescue VcardImport::Parser::TooManyCardsError
    render_upload_error(:too_many_cards)
  rescue VcardImport::Parser::InvalidEncodingError
    render_upload_error(:invalid_file)
  end

  def update
    VcardImport::Importer.call(vcard_import: @vcard_import, selected_candidate_ids:)
    redirect_to friends_path, notice: t("vcard_imports.show.selection_saved")
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.equal?(@vcard_import)

    render :show, status: :unprocessable_entity
  rescue ArgumentError, TypeError
    @vcard_import.errors.add(:selected_candidate_ids, :invalid)
    render :show, status: :unprocessable_entity
  end

  private

  def set_vcard_import
    @vcard_import = Current.user.vcard_imports.find(params[:id])
    return unless @vcard_import.expired?

    @vcard_import.destroy!
    redirect_to new_vcard_import_path, alert: t("vcard_imports.errors.expired")
  end

  def selected_candidate_ids
    params.expect(vcard_import: { selected_candidate_ids: [] })[:selected_candidate_ids]
      .reject(&:blank?)
      .map { |id| Integer(id, 10) }
  end

  def render_upload_error(error)
    @vcard_import = VcardImport.new
    @vcard_import.errors.add(:file, t("vcard_imports.errors.#{error}", **upload_error_options(error)))
    render :new, status: :unprocessable_entity
  end

  def upload_error_options(error)
    case error
    when :file_too_large
      { size: helpers.number_to_human_size(max_file_size) }
    when :too_many_cards
      { count: Rails.application.config.x.vcard_import_max_cards }
    else
      {}
    end
  end

  def max_file_size
    Rails.application.config.x.vcard_import_max_file_size_bytes
  end

  def respond_to_upload_rate_limit
    redirect_to new_vcard_import_path, alert: t("vcard_imports.errors.rate_limited"), status: :see_other
  end
end
