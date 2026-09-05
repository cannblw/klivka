import { Controller } from "@hotwired/stimulus"
import { eventTargetsDialogBackdrop } from "controllers/dialog_events"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean, clearParam: String }

  connect() {
    // Reopens the modal after a failed submit re-renders the page with errors
    if (this.openValue) {
      this.show()
      this.clearLocationParam()
    }

    this.restoreFocus = this.restoreFocus.bind(this)
    this.dialogTarget.addEventListener("close", this.restoreFocus)
  }

  disconnect() {
    this.dialogTarget.removeEventListener("close", this.restoreFocus)
  }

  open(event) {
    if (this.dialogTarget.open) return

    this.opener = event.detail?.opener || event.currentTarget
    this.show()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (eventTargetsDialogBackdrop(this.dialogTarget, event)) this.close()
  }

  restoreFocus() {
    this.opener?.focus()
    this.opener = undefined
  }

  clearLocationParam() {
    if (!this.hasClearParamValue) return

    const url = new URL(window.location.href)
    if (!url.searchParams.has(this.clearParamValue)) return

    url.searchParams.delete(this.clearParamValue)
    window.history.replaceState(window.history.state, "", url)
  }

  show() {
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }
}
