import { Controller } from "@hotwired/stimulus"

const DIALOG_ID = "delete-entry-dialog"
const CONFIRM_ID = "delete-entry-confirm-link"

export default class extends Controller {
  click(event) {
    event.preventDefault()
    const confirmLink = document.getElementById(CONFIRM_ID)
    const url = event.currentTarget.dataset.deleteEntryUrl

    confirmLink.href = url
    confirmLink.dataset.turboMethod = "delete"
    document.getElementById(DIALOG_ID)?.showModal()
  }
}
