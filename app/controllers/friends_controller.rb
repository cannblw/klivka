class FriendsController < ApplicationController
  def index
    @friends = Friend.order(:name)
  end
end
