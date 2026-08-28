class PeopleController < ApplicationController
  def index
    @sort = params[:sort].presence_in(PersonSearch::SORTS.keys) || PersonSearch::DEFAULT_SORT
    @view = params[:view] == "all" ? "all" : "grouped"
    @people = PersonSearch.call(Current.user, params[:query], sort: @sort)
    ActiveRecord::Associations::Preloader.new(records: @people, associations: :category).call
    @grouping_available = Current.user.people.active.where.not(category_id: nil).exists?
    @grouped_view = @grouping_available && @view == "grouped" && params[:query].blank?
    prepare_person_groups if @grouped_view
    @person = Person.new
    @batch_creation = BatchPersonCreation.preview(user: Current.user, names: "")
    @batch_mode = params[:batch] == "true"
  end

  def show
    @person = Current.user.people.friendly.find(params[:id])
    prepare_return_navigation
    @recent_interactions = @person.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
    @interaction_count = @person.interactions.count
    unless @person.archived?
      prepare_quick_interaction
      prepare_categories
    end
  end

  def archived
    @people = Current.user.people.archived.order(:name, :id)
  end

  def update
    @person = Current.user.people.active.friendly.find(params[:id])
    prepare_return_navigation

    if @person.update(person_params)
      redirect_to person_path(@person, **@return_params)
    else
      prepare_quick_interaction
      prepare_categories
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    person = Current.user.people.friendly.find(params[:id])
    redirect_path = person.archived? ? archived_people_path : root_path
    person.destroy!

    redirect_to redirect_path, notice: t(".deleted", name: person.name)
  end

  def archive
    person = Current.user.people.active.friendly.find(params[:id])
    person.archive!
    ReminderDeliveryReconciler.call(user: Current.user)

    redirect_to root_path, notice: t(".archived", name: person.name)
  end

  def restore
    person = Current.user.people.archived.friendly.find(params[:id])
    person.restore!

    redirect_to person_path(person), notice: t(".restored", name: person.name)
  end

  def create
    @person = Current.user.people.new(person_params)

    if @person.save
      redirect_to @person, notice: t(".created", name: @person.name)
    else
      @people = Current.user.people.active.order(:name)
      @batch_creation = BatchPersonCreation.preview(user: Current.user, names: "")
      @batch_mode = false
      render :index, status: :unprocessable_entity
    end
  end

  private

  def prepare_person_groups
    people_by_category = @people.group_by(&:category)
    @categorized_person_groups = people_by_category.except(nil).sort_by { |category, _people| category.normalized_name }
    @uncategorized_people = people_by_category.fetch(nil, [])
  end

  def prepare_return_navigation
    if @person.archived?
      @return_params = {}
      @back_path = archived_people_path
      @back_translation_key = "people.show.back_to_archived"
    elsif params[:from] == "birthdays"
      month = Integer(params[:month], exception: false)
      month = nil unless month&.between?(1, 12)
      @return_params = { from: "birthdays", month: }.compact
      @back_path = birthdays_path(month:)
      @back_translation_key = "people.show.back_to_birthdays"
    elsif params[:from] == "reminders"
      @return_params = { from: "reminders" }
      @back_path = reminders_path
      @back_translation_key = "people.show.back_to_reminders"
    else
      @return_params = {}
      @back_path = root_path
      @back_translation_key = "people.show.back"
    end
  end

  def prepare_quick_interaction
    @recent_interactions = @person.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
    @interaction_count = @person.interactions.count
    @last_interaction = @recent_interactions.first
    @interaction_to_enrich = @person.interactions.new(occurred_on: Date.current)
    @open_interaction_modal = params[:quick_interaction] == "today"
    @contact_reminder = ContactReminder.for(@person)
  end

  def prepare_categories
    @categories = Current.user.categories.order(:normalized_name).to_a
  end

  def person_params
    params.expect(person: [ :name ])
  end
end
