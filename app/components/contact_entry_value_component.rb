class ContactEntryValueComponent < ViewComponent::Base
  def initialize(entry:)
    raise ArgumentError, "unsupported contact entry type: #{entry.class.name}" unless entry.is_a?(Entry::Phone) || entry.is_a?(Entry::Email)

    @entry = entry
  end

  private

  attr_reader :entry

  def value
    @value ||= entry.content&.dig(value_key)
  end

  def label
    entry.content&.dig("label")
  end

  def href
    "#{phone? ? "tel" : "mailto"}:#{value}"
  end

  def copy_label
    t(phone? ? "entries.copy" : "entries.copy_email")
  end

  def value_key
    phone? ? "number" : "email"
  end

  def phone?
    entry.is_a?(Entry::Phone)
  end
end
