import { Controller } from "@hotwired/stimulus"
import { localDateFor } from "lib/local_date"

export default class extends Controller {
  static targets = [ "date", "form", "source", "today" ]

  connect() {
    this.dateTarget.max = localDateFor(new Date())
  }

  submit() {
    const today = localDateFor(new Date())
    this.dateTarget.max = today
    this.todayTarget.value = today
    this.sourceTarget.value = "browser"
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
    const today = localDateFor(new Date())
    this.dateTarget.max = today
    this.dateTarget.value = today
    this.todayTarget.value = today
    this.sourceTarget.value = "browser"
  }
}
