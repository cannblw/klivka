class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ update destroy ]

  def index
    @category = Current.user.categories.new
    prepare_index
  end

  def person_suggestions
    category = Current.user.categories.find(params[:category_id])
    return render json: [] if params[:query].blank?

    people = PersonSearch.call(Current.user, params[:query]).reject { |person| person.category_id == category.id }
    ActiveRecord::Associations::Preloader.new(records: people, associations: :category).call

    render json: people.map { |person| suggestion_for(person) }
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
    person_count = @category.active_people.count
    @category.destroy!

    redirect_to categories_path, notice: t(".deleted", name: @category.name, count: person_count)
  end

  private

  def set_category
    @category = Current.user.categories.find(params[:id])
  end

  def prepare_index
    @categories = Current.user.categories.includes(:active_people).order(:normalized_name).to_a
    @categories.map! { |category| category.id == @category.id ? @category : category } if @category.persisted?
    @uncategorized_people = Current.user.people.active.where(category_id: nil).order(:name, :id).to_a
  end

  def category_params
    params.expect(category: [ :name ])
  end

  def suggestion_for(person)
    {
      name: person.name,
      category: person.category&.name,
      assignment_url: person_category_assignment_path(person)
    }
  end
end
