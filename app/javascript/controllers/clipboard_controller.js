import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const original = this.element.innerHTML
      this.element.innerHTML = '<span class="material-icons" style="font-size:14px">check</span>'
      setTimeout(() => {
        this.element.innerHTML = original
      }, 1500)
    })
  }
}
