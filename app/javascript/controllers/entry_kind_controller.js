import { Controller } from "@hotwired/stimulus"

const FIELD_MAP = {
  "Entry::Phone": "phone-fields",
  "Entry::Note": "note-fields",
  "Entry::Birthday": "birthday-fields"
}

export default class extends Controller {
  static targets = ["phoneFields", "noteFields", "birthdayFields"]

  showFields(event) {
    this.hideAll()
    const target = FIELD_MAP[event.target.value]
    if (target) {
      const fieldsElement = document.getElementById(target)
      if (fieldsElement) fieldsElement.classList.remove("hidden")
    }
  }

  hideAll() {
    this.phoneFieldsTarget?.classList.add("hidden")
    this.noteFieldsTarget?.classList.add("hidden")
    this.birthdayFieldsTarget?.classList.add("hidden")
  }
}
