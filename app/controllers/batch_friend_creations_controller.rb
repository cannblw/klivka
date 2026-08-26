class BatchFriendCreationsController < ApplicationController
  def new
    redirect_to friends_path(batch: true)
  end

  def preview
    @creation = BatchFriendCreation.preview(user: Current.user, names: names_param)

    if @creation.valid?
      render :preview
    else
      prepare_friends_index
      render "friends/index", status: :unprocessable_entity
    end
  end

  def create
    @creation = BatchFriendCreation.from_review(user: Current.user, candidates: candidate_params)

    if @creation.save
      redirect_to friends_path, notice: creation_notice
    else
      render :preview, status: :unprocessable_entity
    end
  end

  private

  def names_param
    params.expect(batch_friend_creation: [ :names ])[:names]
  end

  def candidate_params
    creation_params = params.fetch(:batch_friend_creation, ActionController::Parameters.new)
    permitted = creation_params.permit(candidates: %i[ id name selected ])
    candidates = permitted.fetch(:candidates, [])
    candidates = candidates.values if candidates.respond_to?(:each_value)
    candidates.map(&:to_h)
  end

  def creation_notice
    t(
      ".result",
      created: t(".created", count: @creation.created_friends.size),
      skipped: t(".skipped", count: @creation.skipped_count)
    )
  end

  def prepare_friends_index
    @sort = FriendSearch::DEFAULT_SORT
    @friends = FriendSearch.call(Current.user, nil, sort: @sort)
    @friend = Friend.new
    @batch_creation = @creation
    @batch_mode = true
  end
end
