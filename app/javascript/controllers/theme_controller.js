import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    document.documentElement.dataset.theme = event.target.value
  }
}
