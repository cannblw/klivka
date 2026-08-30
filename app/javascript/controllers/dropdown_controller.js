import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "trigger"]

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    this.close()
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", String(!this.menuTarget.classList.contains("hidden")))
    }
    if (!this.menuTarget.classList.contains("hidden")) {
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
    this.menuTarget.classList.add("hidden")
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.boundClickOutside)
  }

  closeAndFocus() {
    this.close()
    if (this.hasTriggerTarget) this.triggerTarget.focus()
  }
}
