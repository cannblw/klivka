class InteractionsController < ApplicationController
  PAGE_SIZE = 25

  before_action :set_friend
  before_action :set_interaction, only: %i[ edit update destroy ]

  def index
    @page = page_number
    page_results = @friend.interactions.recent.offset((@page - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1).to_a
    @has_next_page = page_results.size > PAGE_SIZE
    @has_previous_page = @page > 1
    @interactions = page_results.first(PAGE_SIZE)
    @total_count = @friend.interactions.count
  end

  def new
    @interaction = @friend.interactions.new(occurred_on: Date.current)
  end

  def create
    @interaction = @friend.interactions.new(interaction_params)
    @interaction.validation_date = browser_date || Date.current
    @interaction.occurred_on = Date.current if server_date_fallback?

    if @interaction.save
      notice = server_date_fallback? ? t("interactions.contacted_today.server_date_fallback") : t("interactions.create.created")
      redirect_to @friend, notice: notice
    elsif params[:context] == "quick_log"
      @interaction_to_enrich = @interaction
      @open_interaction_modal = true
      @recent_interactions = @friend.interactions.recent.limit(InteractionHistoryComponent::PROFILE_PREVIEW_LIMIT).to_a
      @interaction_count = @friend.interactions.count
      @keep_in_touch_setting = @friend.keep_in_touch_setting
      render "friends/show", status: :unprocessable_entity
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @interaction.validation_date = browser_date || Date.current

    if @interaction.update(interaction_params)
      redirect_to @friend, notice: t("interactions.update.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @interaction.destroy!

    redirect_to @friend, notice: t("interactions.destroy.deleted")
  end

  private

  def set_friend
    @friend = Current.user.friends.friendly.find(params[:friend_id])
  end

  def set_interaction
    @interaction = @friend.interactions.find(params[:id])
  end

  def interaction_params
    params.expect(interaction: [ :occurred_on, :contact_method, :note ])
  end

  def server_date_fallback?
    params[:context] == "quick_log" && browser_date.nil?
  end

  def browser_date
    return @browser_date if defined?(@browser_date)

    @browser_date = Date.iso8601(params[:browser_date]) if params[:date_source] == "browser"
  rescue Date::Error, TypeError
    @browser_date = nil
  end

  def page_number
    value = Integer(params[:page], exception: false)
    value&.positive? ? value : 1
  end
end
