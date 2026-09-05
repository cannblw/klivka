import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dialogId: String }

  open(event) {
    event.preventDefault()

    if (!this.hasDialogIdValue) {
      console.error("Dialog trigger target is not configured")
      return
    }

    const dialog = document.getElementById(this.dialogIdValue)
    if (!dialog) {
      console.error("Dialog trigger target is unavailable")
      return
    }

    dialog.dispatchEvent(new CustomEvent("dialog:open", {
      bubbles: true,
      detail: { opener: event.currentTarget }
    }))
  }
}
