class FriendsController < ApplicationController
  def index
    @friends = Current.user.friends.order(:name)
    @friend = Friend.new
  end

  def show
    @friend = Current.user.friends.find(params[:id])
    @new_entry = Entry.new
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

  def friend_params
    params.expect(friend: [ :name ])
  end
end
