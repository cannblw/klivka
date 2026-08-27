import { Controller } from "@hotwired/stimulus"

const DIALOG_ID = "archive-person-dialog"
const CONFIRM_ID = "archive-person-confirm-link"

export default class extends Controller {
  click(event) {
    event.preventDefault()
    const confirmLink = document.getElementById(CONFIRM_ID)
    if (confirmLink) confirmLink.href = event.currentTarget.dataset.archivePersonUrl
    document.getElementById(DIALOG_ID)?.showModal()
  }
}
