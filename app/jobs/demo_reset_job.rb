class DemoResetJob < ApplicationJob
  queue_as :background

  def perform(at: Time.current)
    return unless Rails.application.config.x.demo_mode

    state = DemoState.current(at:)
    state.with_lock do
      return unless state.reset_due?(at:)

      DemoSeeder.reset!
      state.begin_new_cycle!(at:)
      Rails.logger.info("Shared demo data reset")
    end
  end
end
