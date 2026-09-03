import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dialogId: String }

  confirm() {
    const dialog = document.getElementById(this.dialogIdValue)
    if (!dialog) {
      console.error("Account deletion confirmation dialog is unavailable")
      return
    }

    dialog.showModal()
  }
}
