import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean }

  connect() {
    // Reopens the modal after a failed submit re-renders the page with errors
    if (this.openValue) this.dialogTarget.showModal()
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    // The dialog element is only the click target when the backdrop itself is clicked
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }
}
