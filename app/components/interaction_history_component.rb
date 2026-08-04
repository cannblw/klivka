class InteractionHistoryComponent < ViewComponent::Base
  PROFILE_PREVIEW_LIMIT = 3

  def initialize(friend:, interactions:, total_count:, show_view_all: true, heading_key: "interactions.history.heading")
    @friend = friend
    @interactions = interactions || []
    @total_count = total_count.to_i
    @show_view_all = show_view_all
    @heading_key = heading_key
  end

  private

  attr_reader :friend, :interactions, :total_count, :heading_key

  def show_view_all?
    @show_view_all && total_count > interactions.size
  end

  def method_label(interaction)
    return if interaction.contact_method.blank?

    t("interactions.methods.#{interaction.contact_method}")
  end
end
