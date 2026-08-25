class ContactReminderComponent < ViewComponent::Base
  def initialize(friend:, setting:, **options)
    @friend = friend
    @setting = setting
    @extra_classes = options.delete(:class)
    @options = options
  end

  private

  attr_reader :friend, :setting, :options

  def classes
    [
      "rounded-xl border border-stone-200 bg-stone-50 p-4 sm:p-5 dark:border-stone-700 dark:bg-stone-800",
      @extra_classes
    ].compact.join(" ")
  end

  def enabled?
    setting&.enabled?
  end

  def due?
    enabled? && setting.due?(on: Date.current)
  end

  def snoozed?
    enabled? && setting.snoozed?
  end

  def cadence_options
    KeepInTouchSetting::CADENCES.map { |cadence| [ t("contact_reminder.cadences.#{cadence}"), cadence ] }
  end

  def selected_cadence
    setting&.cadence || KeepInTouchSetting::DEFAULT_CADENCE
  end

  def next_suggestion_on
    setting.next_suggestion_on
  end

  def cadence_label
    t("contact_reminder.cadences.#{setting.cadence}")
  end

  def activation_form_action
    setting ? enable_friend_keep_in_touch_setting_path(friend) : friend_keep_in_touch_setting_path(friend)
  end

  def activation_form_method
    setting ? :patch : :post
  end
end
