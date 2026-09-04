import { Controller } from "@hotwired/stimulus"
import { eventTargetsDialogBackdrop } from "controllers/dialog_events"

export default class extends Controller {
  static targets = [ "body", "cancel", "confirm", "form", "method", "title" ]

  open(event) {
    event.preventDefault()
    if (this.element.open) return

    const configuration = event.detail || event.currentTarget?.dataset
    if (!this.valid(configuration)) {
      console.error("Confirmation dialog configuration is incomplete")
      return
    }

    this.opener = document.getElementById(configuration.confirmDialogFocusId) || configuration.opener || event.currentTarget
    this.titleTarget.textContent = configuration.confirmDialogTitle
    this.bodyTarget.textContent = configuration.confirmDialogBody
    this.cancelTarget.textContent = configuration.confirmDialogCancelLabel
    this.confirmTarget.textContent = configuration.confirmDialogConfirmLabel
    this.formTarget.action = configuration.confirmDialogUrl
    this.confirmationEvent = configuration.confirmDialogConfirmationEvent
    this.configureMethod(configuration.confirmDialogTurboMethod)
    this.configureVariant(configuration.confirmDialogDestructive)
    this.element.showModal()
  }

  close() {
    if (this.element.open) this.element.close()
  }

  confirm() {
    if (this.confirmationEvent) window.dispatchEvent(new CustomEvent(this.confirmationEvent))
  }

  closeAfterSubmit(event) {
    if (event.detail.success) this.close()
  }

  closeOnBackdrop(event) {
    if (eventTargetsDialogBackdrop(this.element, event)) this.close()
  }

  restoreFocus() {
    this.opener?.focus()
    this.opener = undefined
    this.confirmationEvent = undefined
  }

  valid(configuration) {
    return configuration &&
      configuration.confirmDialogTitle &&
      configuration.confirmDialogBody &&
      configuration.confirmDialogConfirmLabel &&
      configuration.confirmDialogCancelLabel &&
      configuration.confirmDialogUrl
  }

  configureMethod(method) {
    if (method) {
      this.formTarget.method = "post"
      this.methodTarget.disabled = false
      this.methodTarget.value = method
    } else {
      this.formTarget.method = "get"
      this.methodTarget.disabled = true
      this.methodTarget.value = ""
    }
  }

  configureVariant(destructive) {
    const destructiveClasses = this.confirmTarget.dataset.destructiveClasses
    const primaryClasses = this.confirmTarget.dataset.primaryClasses
    const variantClasses = `${destructiveClasses} ${primaryClasses}`.split(" ")
    const selectedClasses = destructive === "false" ? primaryClasses : destructiveClasses

    this.confirmTarget.classList.remove(...variantClasses)
    this.confirmTarget.classList.add(...selectedClasses.split(" "))
  }
}
