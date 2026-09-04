import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content", "dialog" ]

  toggle() {
    this.contentTargets.forEach(target => target.classList.toggle("hidden"))

    const visibleContent = this.contentTargets.find(target => !target.classList.contains("hidden"))
    if (!visibleContent?.dataset.headingId) {
      console.error("People creation dialog heading is not configured")
      return
    }

    this.dialogTarget.setAttribute("aria-labelledby", visibleContent.dataset.headingId)
    visibleContent.querySelector("[data-people-creation-dialog-target~='focus']")?.focus()
  }
}
