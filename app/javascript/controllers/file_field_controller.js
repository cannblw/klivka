import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "name" ]
  static values = { emptyName: String }

  update() {
    this.nameTarget.textContent = this.inputTarget.files[0]?.name || this.emptyNameValue
  }
}
