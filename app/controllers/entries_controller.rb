class EntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_person, only: %i[ new edit update destroy ]
  before_action :set_entry, only: %i[ edit update destroy ]

  def new
    @entry = Entry.creatable_type(params[:type])&.new(person: @person)
  end

  def create
    @person = Current.user.people.friendly.find(params[:person_id])
    klass = Entry.creatable_type(entry_params[:type])

    unless klass
      @entry = Entry.new(person: @person)
      @entry.errors.add(:type, entry_params[:type].present? ? :inclusion : :blank)
      return render :new, status: :unprocessable_entity
    end

    @entry = klass.new(person: @person)
    @entry.assign_attributes(entry_params)

    if @entry.save
      redirect_to @person, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @entry.update(entry_params_for_update)
      @entry.reload

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@entry), render_to_string(EntryCardComponent.new(entry: @entry, person: @person))),
            contact_actions_stream
          ]
        end
        format.html { render EntryCardComponent.new(entry: @entry, person: @person) }
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
      format.html { redirect_to @entry.person, notice: t(".deleted") }
    end
  end

  def reorder
    @person = Current.user.people.friendly.find(params[:person_id])
    requested_ids = params.expect(entry_ids: []).map(&:to_i)
    entries = @person.entries.index_by(&:id)

    unless requested_ids.length == entries.length &&
        requested_ids.uniq.length == entries.length &&
        requested_ids.all? { |entry_id| entries.key?(entry_id) }
      return render json: { error: t("entries.reorder.invalid_order") }, status: :unprocessable_entity
    end

    Entry.transaction do
      requested_ids.each_with_index do |entry_id, position|
        entries.fetch(entry_id).update_columns(position: position, updated_at: Time.current)
      end
      @person.touch
    end

    head :no_content
  rescue ActionController::ParameterMissing
    render json: { error: t("entries.reorder.invalid_order") }, status: :unprocessable_entity
  end

  private

  def set_person
    @person = Current.user.people.friendly.find(params[:person_id])
  end

  def set_entry
    @entry = @person.entries.find(params[:id])
  end

  def contact_actions_stream
    turbo_stream.replace(
      PersonContactActionsComponent::DOM_ID,
      render_to_string(PersonContactActionsComponent.new(entries: @person.entries.ordered))
    )
  end

  # Create allows setting the STI type; update locks it
  def entry_params
    params.require(:entry).permit(
      :type, :entry_date, :entry_year, :entry_month, :entry_day, :current_age, :birthday_input_basis,
      content: {},
      entry_reminder_attributes: %i[ id lead_value lead_unit recurrence _destroy ]
    )
  end

  def entry_params_for_update
    params.require(:entry).permit(
      :entry_date, :entry_year, :entry_month, :entry_day, :current_age, :birthday_input_basis,
      content: {},
      entry_reminder_attributes: %i[ id lead_value lead_unit recurrence _destroy ]
    )
  end
end
