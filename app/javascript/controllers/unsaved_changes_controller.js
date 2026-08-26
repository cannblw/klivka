import { Controller } from "@hotwired/stimulus"

const DIALOG_ID = "discard-changes-dialog"
const CONFIRM_LINK_ID = "discard-changes-confirm-link"

export default class extends Controller {
  connect() {
    this.isDirty = false
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
    document.getElementById(CONFIRM_LINK_ID)?.addEventListener("click", this.boundHandleDiscard)
  }

  disconnect() {
    this.element.removeEventListener("input", this.boundHandleInput)
    this.element.removeEventListener("change", this.boundHandleInput)
    this.element.removeEventListener("submit", this.boundHandleSubmit)
    document.removeEventListener("turbo:before-visit", this.boundHandleBeforeVisit)
    window.removeEventListener("beforeunload", this.boundHandleBeforeUnload)
    document.getElementById(CONFIRM_LINK_ID)?.removeEventListener("click", this.boundHandleDiscard)
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
    if (!this.isDirty) return
    event.preventDefault()

    const link = document.getElementById(CONFIRM_LINK_ID)
    if (link) link.href = event.detail.url
    document.getElementById(DIALOG_ID)?.showModal()
  }

  handleDiscard() {
    this.isDirty = false
  }

  handleBeforeUnload(event) {
    if (!this.isDirty) return
    event.preventDefault()
    event.returnValue = ""
  }
}
