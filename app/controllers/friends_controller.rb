class FriendsController < ApplicationController
  def index
    @friends = Friend.order(:name)
    @friend = Friend.new
  end

  def show
    @friend = Friend.find(params[:id])
  end

  def create
    @friend = Friend.new(friend_params)

    if @friend.save
      redirect_to @friend, notice: t(".created", name: @friend.name)
    else
      @friends = Friend.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def friend_params
    params.expect(friend: [ :name ])
  end
end
