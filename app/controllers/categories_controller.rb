class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ update destroy ]

  def index
    @category = Current.user.categories.new
    prepare_index
  end

  def friend_suggestions
    category = Current.user.categories.find(params[:category_id])
    return render json: [] if params[:query].blank?

    friends = FriendSearch.call(Current.user, params[:query]).reject { |friend| friend.category_id == category.id }
    ActiveRecord::Associations::Preloader.new(records: friends, associations: :category).call

    render json: friends.map { |friend| suggestion_for(friend) }
  end

  def create
    @category = Current.user.categories.new(category_params)

    if @category.save
      redirect_to categories_path, notice: t(".created", name: @category.name)
    else
      prepare_index
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: t(".updated", name: @category.name)
    else
      @new_category = Current.user.categories.new
      prepare_index
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    friend_count = @category.friends.count
    @category.destroy!

    redirect_to categories_path, notice: t(".deleted", name: @category.name, count: friend_count)
  end

  private

  def set_category
    @category = Current.user.categories.find(params[:id])
  end

  def prepare_index
    @categories = Current.user.categories.includes(:friends).order(:normalized_name).to_a
    @categories.map! { |category| category.id == @category.id ? @category : category } if @category.persisted?
    @uncategorized_friends = Current.user.friends.where(category_id: nil).order(:name, :id).to_a
  end

  def category_params
    params.expect(category: [ :name ])
  end

  def suggestion_for(friend)
    {
      name: friend.name,
      category: friend.category&.name,
      assignment_url: friend_category_assignment_path(friend)
    }
  end
end
