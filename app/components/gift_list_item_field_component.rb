class GiftListItemFieldComponent < ViewComponent::Base
  def initialize(item:, index:, position:)
    @item = item.stringify_keys
    @index = index
    @position = position
  end

  private

  attr_reader :item, :index, :position

  def field_name(attribute)
    "entry[content][items][#{index}][#{attribute}]"
  end
end
