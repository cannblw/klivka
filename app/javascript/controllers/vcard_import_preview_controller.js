import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkbox", "count", "submit", "submitWrapper", "selectionHint" ]
  static values = { singularLabel: String, pluralLabel: String }

  connect() {
    this.updateCount()
  }

  updateCount() {
    const count = this.checkboxTargets.filter((checkbox) => checkbox.checked).length
    this.countTarget.textContent = count === 1
      ? this.singularLabelValue
      : this.pluralLabelValue.replace("__COUNT__", count)

    const selectionRequired = count === 0
    const hintId = this.selectionHintTarget.id
    this.submitTarget.disabled = selectionRequired
    this.submitTarget.toggleAttribute("aria-describedby", selectionRequired)
    if (selectionRequired) this.submitTarget.setAttribute("aria-describedby", hintId)

    this.submitWrapperTarget.classList.toggle("group", selectionRequired)
    this.submitWrapperTarget.tabIndex = selectionRequired ? 0 : -1
    this.submitWrapperTarget.toggleAttribute("aria-describedby", selectionRequired)
    if (selectionRequired) this.submitWrapperTarget.setAttribute("aria-describedby", hintId)
  }
}
