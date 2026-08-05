class EntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_friend, only: %i[ new edit update destroy ]
  before_action :set_entry, only: %i[ edit update destroy ]

  def new
    @entry = Entry.creatable_type(params[:type])&.new(friend: @friend)
  end

  def create
    @friend = Current.user.friends.friendly.find(params[:friend_id])
    klass = Entry.creatable_type(entry_params[:type])

    unless klass
      @entry = Entry.new(friend: @friend)
      @entry.errors.add(:type, entry_params[:type].present? ? :inclusion : :blank)
      return render :new, status: :unprocessable_entity
    end

    @entry = klass.new(friend: @friend)
    @entry.assign_attributes(entry_params)

    if @entry.save
      redirect_to @friend, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @entry.update(entry_params_for_update)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@entry), render_to_string(EntryCardComponent.new(entry: @entry, friend: @friend))),
            contact_actions_stream
          ]
        end
        format.html { render EntryCardComponent.new(entry: @entry, friend: @friend) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@entry)),
          contact_actions_stream
        ]
      end
      format.html { redirect_to @entry.friend, notice: t(".deleted") }
    end
  end

  def reorder
    @friend = Current.user.friends.friendly.find(params[:friend_id])
    requested_ids = params.expect(entry_ids: []).map(&:to_i)
    entries = @friend.entries.index_by(&:id)

    unless requested_ids.length == entries.length &&
        requested_ids.uniq.length == entries.length &&
        requested_ids.all? { |entry_id| entries.key?(entry_id) }
      return render json: { error: t("entries.reorder.invalid_order") }, status: :unprocessable_entity
    end

    Entry.transaction do
      requested_ids.each_with_index do |entry_id, position|
        entries.fetch(entry_id).update_columns(position: position, updated_at: Time.current)
      end
      @friend.touch
    end

    head :no_content
  rescue ActionController::ParameterMissing
    render json: { error: t("entries.reorder.invalid_order") }, status: :unprocessable_entity
  end

  private

  def set_friend
    @friend = Current.user.friends.friendly.find(params[:friend_id])
  end

  def set_entry
    @entry = @friend.entries.find(params[:id])
  end

  def contact_actions_stream
    turbo_stream.replace(
      FriendContactActionsComponent::DOM_ID,
      render_to_string(FriendContactActionsComponent.new(entries: @friend.entries.ordered))
    )
  end

  # Create allows setting the STI type; update locks it
  def entry_params
    params.require(:entry).permit(:type, :entry_date, :entry_year, :entry_month, :entry_day, content: {})
  end

  def entry_params_for_update
    params.require(:entry).permit(:entry_date, :entry_year, :entry_month, :entry_day, content: {})
  end
end
