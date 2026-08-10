import { Controller } from "@hotwired/stimulus"
import { localDateFor } from "lib/local_date"

export default class extends Controller {
  static targets = [ "date", "form" ]
  static values = { timeZone: String }

  connect() {
    this.dateTarget.max = this.today
  }

  submit() {
    this.dateTarget.max = this.today
  }

  openPicker() {
    if (this.dateTarget.showPicker) {
      this.dateTarget.showPicker()
    } else {
      this.dateTarget.focus()
      this.dateTarget.click()
    }
  }

  setCurrentDate() {
    this.formTarget.reset()
    this.dateTarget.max = this.today
    this.dateTarget.value = this.today
  }

  get today() {
    return localDateFor(new Date(), this.timeZoneValue)
  }
}
