import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    event.preventDefault()
    const focusId = this.element.dataset.confirmDialogFocusId
    const opener = focusId ? document.getElementById(focusId) : event.currentTarget

    window.dispatchEvent(new CustomEvent("confirm-dialog:open", {
      detail: {
        confirmDialogUrl: this.element.dataset.confirmDialogUrl,
        confirmDialogTitle: this.element.dataset.confirmDialogTitle,
        confirmDialogBody: this.element.dataset.confirmDialogBody,
        confirmDialogConfirmLabel: this.element.dataset.confirmDialogConfirmLabel,
        confirmDialogCancelLabel: this.element.dataset.confirmDialogCancelLabel,
        confirmDialogTurboMethod: this.element.dataset.confirmDialogTurboMethod,
        confirmDialogDestructive: this.element.dataset.confirmDialogDestructive,
        confirmDialogConfirmationEvent: this.element.dataset.confirmDialogConfirmationEvent,
        opener
      }
    }))
  }
}
