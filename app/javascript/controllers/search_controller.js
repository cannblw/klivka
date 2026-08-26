import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "sort" ]
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

  submit() {
    this.clearPendingSearch()
    this.element.requestSubmit()
  }

  prepareFormData(event) {
    if (event.formData.get("query") === "") event.formData.delete("query")
    if (event.formData.get("sort") === "") event.formData.delete("sort")
    if (event.formData.get("view") === "") event.formData.delete("view")
  }

  clearPendingSearch() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      this.timeout = null
    }
  }
}
