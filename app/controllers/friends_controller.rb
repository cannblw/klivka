class FriendsController < ApplicationController
  def index
    @sort = params[:sort].presence_in(FriendSearch::SORTS.keys) || FriendSearch::DEFAULT_SORT
    @view = params[:view] == "all" ? "all" : "grouped"
    @friends = FriendSearch.call(Current.user, params[:query], sort: @sort)
    ActiveRecord::Associations::Preloader.new(records: @friends, associations: :category).call
    @grouping_available = Current.user.friends.where.not(category_id: nil).exists?
    @grouped_view = @grouping_available && @view == "grouped" && params[:query].blank?
    prepare_friend_groups if @grouped_view
    @friend = Friend.new
  end

  def show
    @friend = Current.user.friends.friendly.find(params[:id])
    prepare_return_navigation
    @recent_interactions = @friend.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
    @interaction_count = @friend.interactions.count
    prepare_quick_interaction
    prepare_categories
  end

  def update
    @friend = Current.user.friends.friendly.find(params[:id])
    prepare_return_navigation

    if @friend.update(friend_params)
      redirect_to friend_path(@friend, **@return_params)
    else
      prepare_quick_interaction
      prepare_categories
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

  def prepare_friend_groups
    friends_by_category = @friends.group_by(&:category)
    @categorized_friend_groups = friends_by_category.except(nil).sort_by { |category, _friends| category.normalized_name }
    @uncategorized_friends = friends_by_category.fetch(nil, [])
  end

  def prepare_return_navigation
    if params[:from] == "birthdays"
      month = Integer(params[:month], exception: false)
      month = nil unless month&.between?(1, 12)
      @return_params = { from: "birthdays", month: }.compact
      @back_path = birthdays_path(month:)
      @back_translation_key = "friends.show.back_to_birthdays"
    else
      @return_params = {}
      @back_path = root_path
      @back_translation_key = "friends.show.back"
    end
  end

  def prepare_quick_interaction
    @recent_interactions = @friend.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
    @interaction_count = @friend.interactions.count
    @last_interaction = @recent_interactions.first
    @interaction_to_enrich = @friend.interactions.new(occurred_on: Date.current)
    @open_interaction_modal = params[:quick_interaction] == "today"
    @keep_in_touch_setting = @friend.keep_in_touch_setting
  end

  def prepare_categories
    @categories = Current.user.categories.order(:normalized_name).to_a
  end

  def friend_params
    params.expect(friend: [ :name ])
  end
end
