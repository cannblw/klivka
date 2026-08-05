class FriendsController < ApplicationController
  def index
    @sort = params[:sort].presence_in(FriendSearch::SORTS.keys) || FriendSearch::DEFAULT_SORT
    @friends = FriendSearch.call(Current.user, params[:query], sort: @sort)
    @friend = Friend.new
  end

  def show
    @friend = Current.user.friends.friendly.find(params[:id])
    @recent_interactions = @friend.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
    @interaction_count = @friend.interactions.count
    prepare_quick_interaction
  end

  def update
    @friend = Current.user.friends.friendly.find(params[:id])

    if @friend.update(friend_params)
      redirect_to @friend
    else
      prepare_quick_interaction
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    friend = Current.user.friends.friendly.find(params[:id])
    friend.destroy

    redirect_to root_path, notice: t(".deleted", name: friend.name)
  end

  def create
    @friend = Current.user.friends.new(friend_params)

    if @friend.save
      redirect_to @friend, notice: t(".created", name: @friend.name)
    else
      @friends = Current.user.friends.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def prepare_quick_interaction
    @recent_interactions = @friend.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
    @interaction_count = @friend.interactions.count
    @interaction_to_enrich = @friend.interactions.new(occurred_on: Date.current)
    @open_interaction_modal = false
  end

  def friend_params
    params.expect(friend: [ :name ])
  end
end
