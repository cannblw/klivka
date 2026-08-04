class FriendsController < ApplicationController
  def index
    @sort = params[:sort].presence_in(FriendSearch::SORTS.keys) || FriendSearch::DEFAULT_SORT
    @friends = FriendSearch.call(Current.user, params[:query], sort: @sort)
    @friend = Friend.new
  end

  def show
    @friend = Current.user.friends.find(params[:id])
    prepare_quick_interaction
  end

  def update
    @friend = Current.user.friends.find(params[:id])

    if @friend.update(friend_params)
      redirect_to @friend
    else
      prepare_quick_interaction
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    friend = Current.user.friends.find(params[:id])
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
    @interaction_to_enrich = @friend.interactions.new(occurred_on: Date.current)
    @open_interaction_modal = false
  end

  def friend_params
    params.expect(friend: [ :name ])
  end
end
