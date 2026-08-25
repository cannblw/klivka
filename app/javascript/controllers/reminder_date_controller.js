import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "addButton", "date", "destroyField", "fields", "notice", "recurrence" ]
  static values = { yearlyRecurrence: String }

  connect() {
    this.update()
  }

  update() {
    this.fieldsTarget.classList.toggle("hidden", !this.enabled)
    this.addButtonTarget.classList.toggle("hidden", this.enabled)
    this.noticeTarget.classList.toggle("hidden", !this.enabled || !this.repeatsYearly || !this.leapDay)
    this.addButtonTarget.querySelector("button").setAttribute("aria-expanded", this.enabled.toString())
  }

  enable() {
    this.destroyFieldTarget.value = "0"
    this.update()
    this.fieldsTarget.querySelector("input:not([type='hidden']), select")?.focus()
  }

  disable() {
    this.destroyFieldTarget.value = "1"
    this.update()
    this.addButtonTarget.querySelector("button").focus()
  }

  get enabled() {
    return this.destroyFieldTarget.value !== "1"
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
