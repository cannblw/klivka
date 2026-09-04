class PeopleController < ApplicationController
  def index
    prepare_people_index
    @person = Person.new
    @batch_creation = BatchPersonCreation.preview(user: Current.user, names: "")
    @batch_mode = params[:batch] == "true"
  end

  def show
    @person = Current.user.people.friendly.find(params[:id])
    prepare_return_navigation
    prepare_interaction_summary
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
      prepare_interaction_summary
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
      prepare_people_index
      @batch_creation = BatchPersonCreation.preview(user: Current.user, names: "")
      @batch_mode = false
      render :index, status: :unprocessable_entity
    end
  end

  private

  def prepare_people_index
    @people_query = PeopleQuery.new(
      Current.user,
      params[:query],
      sort: params[:sort],
      filters: people_query_filter_params
    )
    @sort = @people_query.sort
    @view = params[:view] == "all" ? "all" : "grouped"
    @people = @people_query.call
    @filter_categories = Current.user.categories.order(:normalized_name).to_a
    ActiveRecord::Associations::Preloader.new(records: @people, associations: :category).call
    @grouping_available = Current.user.people.active.where.not(category_id: nil).exists?
    @grouped_view = @grouping_available && @view == "grouped" && @people_query.query.blank? && !@people_query.filtered?
    prepare_person_groups if @grouped_view
  end

  def people_query_filter_params
    params.permit(
      :birthday,
      :last_contact,
      :category,
      :state,
      :contact_reminder,
      :date_reminder,
      has_blocks: [],
      missing_blocks: []
    ).to_h
  end

  def prepare_person_groups
    people_by_category = @people.group_by(&:category)
    @categorized_person_groups = people_by_category.except(nil).sort_by { |category, _people| category.normalized_name }
    @uncategorized_people = people_by_category.fetch(nil, [])
  end

  def prepare_return_navigation
    @return_params = {}

    if @person.archived?
      @back_path = archived_people_path
    else
      @back_path = root_path
    end
  end

  def prepare_quick_interaction
    @last_interaction = @recent_interactions.first
    @interaction_to_enrich = @person.interactions.new(occurred_on: Date.current)
    @open_interaction_modal = params[:quick_interaction] == "today"
    @contact_reminder = ContactReminder.for(@person)
  end

  def prepare_interaction_summary
    @recent_interactions = @person.interactions.recent.limit(interaction_profile_preview_limit).to_a
    @interaction_count = @person.interactions.count
  end

  def prepare_categories
    @categories = Current.user.categories.order(:normalized_name).to_a
  end

  def interaction_profile_preview_limit
    Rails.application.config.x.interaction_profile_preview_limit
  end

  def person_params
    params.expect(person: [ :name ])
  end
end
