import { Controller } from "@hotwired/stimulus"

const DIALOG_ID = "delete-person-dialog"
const CONFIRM_ID = "delete-person-confirm-link"

export default class extends Controller {
  click(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.deletePersonUrl
    const confirmLink = document.getElementById(CONFIRM_ID)
    if (confirmLink) {
      confirmLink.href = url
    }
    document.getElementById(DIALOG_ID)?.showModal()
  }
}
