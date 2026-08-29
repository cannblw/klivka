import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "filter", "clear" ]
  static values = { delay: Number }

  connect() {
    this.timeout = null
    this.updateClearButton()
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
    this.updateClearButton()
    this.element.requestSubmit()
  }

  clearFilters() {
    this.filterTargets.forEach((control) => {
      if (control.type === "checkbox") {
        control.checked = false
      } else {
        control.value = control.name === "state" ? "active" : ""
      }
    })
    this.submit()
  }

  prepareFormData(event) {
    const optionalParameters = [
      "query",
      "sort",
      "view",
      "birthday",
      "last_contact",
      "category",
      "state",
      "contact_reminder",
      "date_reminder"
    ]

    optionalParameters.forEach((parameter) => {
      if (event.formData.get(parameter) === "") event.formData.delete(parameter)
    })
    if (event.formData.get("state") === "active") event.formData.delete("state")
  }

  clearPendingSearch() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      this.timeout = null
    }
  }

  updateClearButton() {
    if (!this.hasClearTarget) return

    const active = this.filterTargets.some((control) => {
      if (control.type === "checkbox") return control.checked
      if (control.name === "state") return control.value !== "active"

      return control.value !== ""
    })
    this.clearTarget.hidden = !active
  }
}
