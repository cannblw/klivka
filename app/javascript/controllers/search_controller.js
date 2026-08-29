import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "filter", "clear" ]
  static values = { delay: Number }

  connect() {
    this.timeout = null
    this.restoreFromLocation = this.restoreFromLocation.bind(this)
    window.addEventListener("popstate", this.restoreFromLocation)
    this.updateClearButton()
  }

  disconnect() {
    this.clearPendingSearch()
    window.removeEventListener("popstate", this.restoreFromLocation)
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

  restoreFromLocation() {
    const parameters = new URL(window.location.href).searchParams

    Array.from(this.element.elements).forEach((control) => {
      if (!control.name) return

      if (control.type === "checkbox") {
        control.checked = parameters.getAll(control.name).includes(control.value)
      } else if ([ "query", "sort", "view", "birthday", "last_contact", "category", "state", "contact_reminder", "date_reminder" ].includes(control.name)) {
        control.value = parameters.get(control.name) || (control.name === "state" ? "active" : "")
      }
    })
    this.updateClearButton()
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
