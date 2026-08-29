class ContactMethodsController < ApplicationController
  before_action :set_contact_method, only: %i[ update ]

  def index
    @contact_method = Current.user.contact_methods.new(enabled: true, position: next_position)
    prepare_index
  end

  def create
    @contact_method = Current.user.contact_methods.new(
      contact_method_params.merge(enabled: true, provided: false, position: next_position)
    )

    if @contact_method.save
      redirect_to contact_methods_path, notice: t(".created", name: @contact_method.name)
    else
      prepare_index
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @contact_method.update(contact_method_params)
      redirect_to contact_methods_path, notice: t(".updated", name: @contact_method.name)
    else
      @new_contact_method = Current.user.contact_methods.new(enabled: true, position: next_position)
      prepare_index
      render :index, status: :unprocessable_entity
    end
  end

  def enable
    contact_method = Current.user.contact_methods.disabled.provided.find(params[:id])
    contact_method.update!(enabled: true, position: next_position)

    redirect_to contact_methods_path, notice: t(".enabled", name: contact_method.name)
  end

  def disable
    contact_method = Current.user.contact_methods.enabled.provided.find(params[:id])

    ContactMethod.transaction do
      contact_method.update!(enabled: false, position: nil)
      compact_positions
    end

    redirect_to contact_methods_path, notice: t(".disabled", name: contact_method.name)
  end

  def destroy
    contact_method = Current.user.contact_methods.enabled.where(provided: false).find(params[:id])

    ContactMethod.transaction do
      contact_method.destroy!
      compact_positions
    end

    redirect_to contact_methods_path, notice: t(".destroyed", name: contact_method.name)
  end

  def reorder
    requested_ids = params.expect(contact_method_ids: []).map(&:to_i)
    contact_methods = Current.user.contact_methods.enabled.index_by(&:id)

    unless requested_ids.length == contact_methods.length &&
        requested_ids.uniq.length == contact_methods.length &&
        requested_ids.all? { |contact_method_id| contact_methods.key?(contact_method_id) }
      return render json: { error: t(".invalid_order") }, status: :unprocessable_entity
    end

    ContactMethod.transaction do
      requested_ids.each_with_index do |contact_method_id, position|
        contact_methods.fetch(contact_method_id).update_columns(position:, updated_at: Time.current)
      end
    end

    head :no_content
  rescue ActionController::ParameterMissing
    render json: { error: t(".invalid_order") }, status: :unprocessable_entity
  end

  private

  def set_contact_method
    @contact_method = Current.user.contact_methods.enabled.find(params[:id])
  end

  def contact_method_params
    params.expect(contact_method: %i[ name icon ])
  end

  def prepare_index
    @enabled_contact_methods = Current.user.contact_methods.enabled.ordered.to_a
    if @contact_method&.persisted?
      @enabled_contact_methods.map! do |contact_method|
        contact_method.id == @contact_method.id ? @contact_method : contact_method
      end
    end
    @available_contact_methods = Current.user.contact_methods.disabled.provided.order(:normalized_name, :id).to_a
  end

  def next_position
    (Current.user.contact_methods.enabled.maximum(:position) || -1) + 1
  end

  def compact_positions
    Current.user.contact_methods.enabled.ordered.each_with_index do |contact_method, position|
      contact_method.update_columns(position:, updated_at: Time.current) unless contact_method.position == position
    end
  end
end
