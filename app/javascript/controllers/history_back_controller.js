import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigate(event) {
    if (!this.ordinaryClick(event) || !this.hasSafeHistory()) return

    event.preventDefault()
    window.history.back()
  }

  ordinaryClick(event) {
    return event.button === 0 && !event.metaKey && !event.ctrlKey && !event.shiftKey && !event.altKey
  }

  hasSafeHistory() {
    if (window.navigation?.currentEntry && typeof window.navigation.entries === "function") {
      const previousEntry = window.navigation.entries().find((entry) => {
        return entry.index === window.navigation.currentEntry.index - 1
      })

      return previousEntry && new URL(previousEntry.url).origin === window.location.origin
    }

    if (window.history.length <= 1 || !document.referrer) return false

    return new URL(document.referrer).origin === window.location.origin
  }
}
