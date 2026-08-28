class InteractionsController < ApplicationController
  PAGE_SIZE = 25

  before_action :set_person
  before_action :set_interaction, only: %i[ edit update destroy ]

  def index
    @page = page_number
    page_results = @person.interactions.recent.offset((@page - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1).to_a
    @has_next_page = page_results.size > PAGE_SIZE
    @has_previous_page = @page > 1
    @interactions = page_results.first(PAGE_SIZE)
    @total_count = @person.interactions.count
  end

  def new
    @interaction = @person.interactions.new(occurred_on: Date.current)
  end

  def create
    @interaction = @person.interactions.new(interaction_params)
    @interaction.validation_date = Current.user.local_date

    if save_interaction_and_update_reminder(clear_snooze: true)
      redirect_to interaction_create_redirect_path, notice: t("interactions.create.created")
    elsif quick_log_from_reminders?
      @due_contact_reminders = DueContactRemindersQuery.call(user: Current.user)
      @interactions_by_person_id = { @person.id => @interaction }
      @open_interaction_person_id = @person.id
      render "reminders/index", status: :unprocessable_entity
    elsif params[:context] == "quick_log"
      @interaction_to_enrich = @interaction
      @open_interaction_modal = true
      @recent_interactions = @person.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
      @interaction_count = @person.interactions.count
      @contact_reminder = ContactReminder.for(@person)
      @categories = Current.user.categories.order(:normalized_name).to_a
      render "people/show", status: :unprocessable_entity
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @interaction.validation_date = Current.user.local_date
    @interaction.assign_attributes(interaction_params)

    if save_interaction_and_update_reminder(clear_snooze: @interaction.will_save_change_to_occurred_on?)
      redirect_to @person, notice: t("interactions.update.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @interaction.destroy!

    redirect_to @person, notice: t("interactions.destroy.deleted")
  end

  private

  def set_person
    people = action_name == "index" ? Current.user.people : Current.user.people.active
    @person = people.friendly.find(params[:person_id])
  end

  def set_interaction
    @interaction = @person.interactions.find(params[:id])
  end

  def interaction_params
    params.expect(interaction: [ :occurred_on, :contact_method, :note ])
  end

  def save_interaction_and_update_reminder(clear_snooze:)
    @person.transaction do
      reminder = ContactReminder.for(@person)

      next false unless @interaction.save

      reminder.clear_snooze_for_latest_interaction!(@interaction) if clear_snooze
      true
    end
  end

  def interaction_create_redirect_path
    quick_log_from_reminders? ? reminders_path : @person
  end

  def quick_log_from_reminders?
    params[:context] == "quick_log" && params[:return_to] == "reminders"
  end

  def page_number
    value = Integer(params[:page], exception: false)
    value&.positive? ? value : 1
  end
end
