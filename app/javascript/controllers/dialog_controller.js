import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { open: Boolean, clearParam: String }

  connect() {
    // Reopens the modal after a failed submit re-renders the page with errors
    if (this.openValue) {
      this.dialogTarget.showModal()
      this.clearLocationParam()
    }

    this.restoreFocus = this.restoreFocus.bind(this)
    this.dialogTarget.addEventListener("close", this.restoreFocus)
  }

  disconnect() {
    this.dialogTarget.removeEventListener("close", this.restoreFocus)
  }

  open(event) {
    this.opener = event.detail?.opener || event.currentTarget
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    // The dialog element is only the click target when the backdrop itself is clicked
    if (event.target === this.dialogTarget) this.dialogTarget.close()
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
}
