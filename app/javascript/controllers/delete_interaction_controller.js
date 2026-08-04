import { Controller } from "@hotwired/stimulus"

const DIALOG_ID = "delete-interaction-dialog"
const CONFIRM_ID = "delete-interaction-confirm-link"

export default class extends Controller {
  click(event) {
    event.preventDefault()
    const confirmLink = document.getElementById(CONFIRM_ID)
    confirmLink.href = event.currentTarget.dataset.deleteInteractionUrl
    confirmLink.dataset.turboMethod = "delete"
    document.getElementById(DIALOG_ID)?.showModal()
  }
}
