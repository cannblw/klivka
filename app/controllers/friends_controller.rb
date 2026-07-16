class FriendsController < ApplicationController
  def index
    @friends = Current.user.friends.order(:name)
    @friend = Friend.new
  end

  def show
    @friend = Current.user.friends.find(params[:id])
    @new_entry = Entry.new
  end

  def update
    @friend = Current.user.friends.find(params[:id])

    if @friend.update(friend_params)
      redirect_to @friend
    else
      @new_entry = Entry.new
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

  def friend_params
    params.expect(friend: [ :name ])
  end
end
