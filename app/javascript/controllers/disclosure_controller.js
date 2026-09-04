import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "trigger"]

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    this.close()
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle() {
    this.panelTarget.classList.toggle("hidden")
    this.triggerTarget.setAttribute("aria-expanded", String(!this.panelTarget.classList.contains("hidden")))
    if (!this.panelTarget.classList.contains("hidden")) {
      document.addEventListener("click", this.boundClickOutside)
    } else {
      document.removeEventListener("click", this.boundClickOutside)
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.boundClickOutside)
  }

  closeAndFocus() {
    this.close()
    this.triggerTarget.focus()
  }
}
