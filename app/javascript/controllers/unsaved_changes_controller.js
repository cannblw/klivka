import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    confirmLabel: String,
    cancelLabel: String,
    title: String,
    body: String
  }

  connect() {
    this.isDirty = false
    this.allowNextVisit = false
    this.snapshots = new Map()
    this.snapshotFields()

    this.boundHandleInput = this.handleInput.bind(this)
    this.boundHandleSubmit = this.handleSubmit.bind(this)
    this.boundHandleBeforeVisit = this.handleBeforeVisit.bind(this)
    this.boundHandleBeforeUnload = this.handleBeforeUnload.bind(this)
    this.boundHandleDiscard = this.handleDiscard.bind(this)

    this.element.addEventListener("input", this.boundHandleInput)
    this.element.addEventListener("change", this.boundHandleInput)
    this.element.addEventListener("submit", this.boundHandleSubmit)
    document.addEventListener("turbo:before-visit", this.boundHandleBeforeVisit)
    window.addEventListener("beforeunload", this.boundHandleBeforeUnload)
    window.addEventListener("unsaved-changes:discard-confirmed", this.boundHandleDiscard)
  }

  disconnect() {
    this.element.removeEventListener("input", this.boundHandleInput)
    this.element.removeEventListener("change", this.boundHandleInput)
    this.element.removeEventListener("submit", this.boundHandleSubmit)
    document.removeEventListener("turbo:before-visit", this.boundHandleBeforeVisit)
    window.removeEventListener("beforeunload", this.boundHandleBeforeUnload)
    window.removeEventListener("unsaved-changes:discard-confirmed", this.boundHandleDiscard)
  }

  snapshotFields() {
    for (const field of this.element.querySelectorAll("input, textarea, select")) {
      this.snapshots.set(field, this.fieldValue(field))
    }
  }

  fieldValue(field) {
    if (field.type === "checkbox" || field.type === "radio") return field.checked
    return field.value
  }

  handleInput() {
    for (const [field, original] of this.snapshots) {
      if (this.fieldValue(field) !== original) {
        this.isDirty = true
        return
      }
    }
    this.isDirty = false
  }

  handleSubmit() {
    this.isDirty = false
  }

  handleBeforeVisit(event) {
    if (this.allowNextVisit) {
      this.allowNextVisit = false
      this.isDirty = false
      return
    }

    if (!this.isDirty) return
    event.preventDefault()

    window.dispatchEvent(new CustomEvent("confirm-dialog:open", {
      detail: {
        confirmDialogUrl: event.detail.url,
        confirmDialogTitle: this.titleValue,
        confirmDialogBody: this.bodyValue,
        confirmDialogConfirmLabel: this.confirmLabelValue,
        confirmDialogCancelLabel: this.cancelLabelValue,
        confirmDialogDestructive: "true",
        confirmDialogConfirmationEvent: "unsaved-changes:discard-confirmed",
        opener: document.activeElement
      }
    }))
  }

  handleDiscard() {
    this.allowNextVisit = true
  }

  handleBeforeUnload(event) {
    if (!this.isDirty) return
    event.preventDefault()
    event.returnValue = ""
  }
}
