import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "date", "form", "source", "today" ]

  connect() {
    this.dateTarget.max = this.localDateFor(new Date())
  }

  submit() {
    const today = this.localDateFor(new Date())
    this.dateTarget.max = today
    this.todayTarget.value = today
    this.sourceTarget.value = "browser"
  }

  setCurrentDate() {
    this.formTarget.reset()
    const today = this.localDateFor(new Date())
    this.dateTarget.max = today
    this.dateTarget.value = today
    this.todayTarget.value = today
    this.sourceTarget.value = "browser"
  }

  localDateFor(date) {
    const offsetInMilliseconds = date.getTimezoneOffset() * 60 * 1000
    return new Date(date.getTime() - offsetInMilliseconds).toISOString().slice(0, 10)
  }
}
