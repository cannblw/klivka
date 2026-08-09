import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open() {
    this.dispatch("open", {
      prefix: "quick-interaction",
      target: window,
      detail: { opener: this.element }
    })
  }
}
