import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "date", "enabled", "notice", "recurrence" ]
  static values = { yearlyRecurrence: String }

  connect() {
    this.update()
  }

  update() {
    this.noticeTarget.classList.toggle("hidden", !this.enabledTarget.checked || !this.repeatsYearly || !this.leapDay)
  }

  get leapDay() {
    return this.dateTarget.value.endsWith("-02-29")
  }

  get repeatsYearly() {
    return this.recurrenceTargets.some(target => {
      return target.value === this.yearlyRecurrenceValue && (target.type === "hidden" || target.checked)
    })
  }
}
