class BatchPersonCreationsController < ApplicationController
  def new
    redirect_to people_path(batch: true)
  end

  def preview
    @creation = BatchPersonCreation.preview(user: Current.user, names: names_param)

    if @creation.valid?
      render :preview
    else
      prepare_people_index
      render "people/index", status: :unprocessable_entity
    end
  end

  def create
    @creation = BatchPersonCreation.from_review(user: Current.user, candidates: candidate_params)

    if @creation.save
      redirect_to people_path, notice: creation_notice
    else
      render :preview, status: :unprocessable_entity
    end
  end

  private

  def names_param
    params.expect(batch_person_creation: [ :names ])[:names]
  end

  def candidate_params
    creation_params = params.fetch(:batch_person_creation, ActionController::Parameters.new)
    permitted = creation_params.permit(candidates: %i[ id name selected ])
    candidates = permitted.fetch(:candidates, [])
    candidates = candidates.values if candidates.respond_to?(:each_value)
    candidates.map(&:to_h)
  end

  def creation_notice
    t(
      ".result",
      created: t(".created", count: @creation.created_people.size),
      skipped: t(".skipped", count: @creation.skipped_count)
    )
  end

  def prepare_people_index
    @sort = PersonSearch::DEFAULT_SORT
    @people = PersonSearch.call(Current.user, nil, sort: @sort)
    @person = Person.new
    @batch_creation = @creation
    @batch_mode = true
  end
end
