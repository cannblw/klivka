class InteractionsController < ApplicationController
  before_action :set_friend
  before_action :set_interaction, only: %i[ edit update destroy ]

  def index
    @interactions = @friend.interactions.recent
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
      render "friends/show", status: :unprocessable_entity
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
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
    @friend = Current.user.friends.find(params[:friend_id])
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
end
