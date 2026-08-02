import { Controller } from "@hotwired/stimulus"

const FIELD_MAP = {
  "Entry::Phone": "phone-fields",
  "Entry::Note": "note-fields",
  "Entry::Birthday": "birthday-fields",
  "Entry::Email": "email-fields"
}

export default class extends Controller {
  static targets = ["phoneFields", "noteFields", "birthdayFields", "emailFields"]

  showFields(event) {
    this.hideAll()
    const target = FIELD_MAP[event.target.value]
    if (target) {
      const fieldsElement = document.getElementById(target)
      if (fieldsElement) {
        fieldsElement.classList.remove("hidden")
        fieldsElement.disabled = false
      }
    }
  }

  hideAll() {
    this.constructor.targets.forEach((targetName) => {
      const fieldsElement = this[`${targetName}Target`]
      fieldsElement?.classList.add("hidden")
      if (fieldsElement) fieldsElement.disabled = true
    })
  }
}
