import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: Number }

  connect() {
    this.timeout = null
  }

  disconnect() {
    this.clearPendingSearch()
  }

  debounce() {
    this.clearPendingSearch()
    this.timeout = window.setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  clearPendingSearch() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      this.timeout = null
    }
  }
}
