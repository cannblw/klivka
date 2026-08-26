import { Controller } from "@hotwired/stimulus"

const DIALOG_ID = "delete-category-dialog"
const CONFIRM_ID = "delete-category-confirm-link"
const BODY_ID = `${DIALOG_ID}-body`

export default class extends Controller {
  click(event) {
    event.preventDefault()

    const confirmLink = document.getElementById(CONFIRM_ID)
    const body = document.getElementById(BODY_ID)
    if (confirmLink) confirmLink.href = this.element.dataset.deleteCategoryUrl
    if (body) body.textContent = this.element.dataset.deleteCategoryMessage

    document.getElementById(DIALOG_ID)?.showModal()
  }
}
