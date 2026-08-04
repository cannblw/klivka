class InteractionsController < ApplicationController
  before_action :set_friend
  before_action :set_interaction, only: %i[ edit update destroy ]

  def index
    @interactions = @friend.interactions.recent
  end

  def new
    @interaction = @friend.interactions.new(occurred_at: Time.current)
  end

  def create
    @interaction = @friend.interactions.new(interaction_params)

    if @interaction.save
      redirect_to @friend, notice: t("interactions.create.created")
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

  def contacted_today
    occurred_at, used_server_time = occurred_at_from_browser
    @friend.interactions.create!(occurred_at: occurred_at)

    notice = used_server_time ? t("interactions.contacted_today.server_time_fallback") : t("interactions.create.created")
    redirect_to @friend, notice: notice
  end

  private

  def set_friend
    @friend = Current.user.friends.find(params[:friend_id])
  end

  def set_interaction
    @interaction = @friend.interactions.find(params[:id])
  end

  def interaction_params
    params.expect(interaction: [ :occurred_at, :contact_method, :note ])
  end

  def occurred_at_from_browser
    server_time = Time.current
    browser_value = params[:occurred_at].presence
    return [ server_time, true ] unless browser_value

    browser_time = Time.iso8601(browser_value)
    return [ server_time, true ] if browser_time > server_time

    [ browser_time, false ]
  rescue ArgumentError
    [ server_time, true ]
  end
end
