import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "cadence", "changed", "input", "panel", "savedSchedule", "unsavedSchedule" ]

  connect() {
    this.update()
  }

  update() {
    const cadence = this.cadenceTarget.value

    this.panelTargets.forEach(panel => {
      const active = panel.dataset.cadence === cadence
      panel.classList.toggle("hidden", !active)
      panel.querySelectorAll("input, select").forEach(input => { input.disabled = !active })
    })
  }

  change() {
    this.markChanged()
    this.update()
  }

  markChanged() {
    this.changedTarget.value = "1"
    if (this.hasSavedScheduleTarget) this.savedScheduleTarget.classList.add("hidden")
    if (this.hasUnsavedScheduleTarget) this.unsavedScheduleTarget.classList.remove("hidden")
  }
}
