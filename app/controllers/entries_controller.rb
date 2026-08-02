class EntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_friend, :set_entry, only: %i[ edit update destroy ]

  def create
    @friend = Current.user.friends.find(params[:friend_id])
    klass = Entry.creatable_type(entry_params[:type])

    unless klass
      @entry = Entry.new(friend: @friend)
      @entry.errors.add(:type, entry_params[:type].present? ? :inclusion : :blank)
      @new_entry = @entry
      return render "friends/show", status: :unprocessable_entity
    end

    @entry = klass.new(friend: @friend)
    @entry.assign_attributes(entry_params)

    if @entry.save
      redirect_to @friend, notice: t(".created")
    else
      @new_entry = @entry
      render "friends/show", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @entry.update(entry_params_for_update)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@entry), partial: "entries/card", locals: { entry: @entry, friend: @friend }),
            contact_actions_stream
          ]
        end
        format.html { render partial: "entries/card", locals: { entry: @entry, friend: @friend } }
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

  private

  def set_friend
    @friend = Current.user.friends.find(params[:friend_id])
  end

  def set_entry
    @entry = @friend.entries.find(params[:id])
  end

  def contact_actions_stream
    turbo_stream.replace(
      FriendContactActionsComponent::DOM_ID,
      render_to_string(FriendContactActionsComponent.new(entries: @friend.entries.order(created_at: :desc, id: :desc)))
    )
  end

  # Create allows setting the STI type; update locks it
  def entry_params
    params.require(:entry).permit(:type, :entry_date, content: {})
  end

  def entry_params_for_update
    params.require(:entry).permit(:entry_date, content: {})
  end
end
