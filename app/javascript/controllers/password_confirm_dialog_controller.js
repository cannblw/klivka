import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "error", "password" ]

  connect() {
    this.reset = this.reset.bind(this)
    this.element.addEventListener("close", this.reset)
  }

  disconnect() {
    this.element.removeEventListener("close", this.reset)
  }

  input() {
    this.errorTarget.hidden = true
    this.errorTarget.textContent = ""
  }

  reset() {
    this.passwordTarget.value = ""
    this.input()
  }
}
