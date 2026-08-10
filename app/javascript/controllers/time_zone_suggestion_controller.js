import { Controller } from "@hotwired/stimulus"
import { browserTimeZone } from "lib/browser_time_zone"

const dismissalKeyPrefix = "klivka.time-zone-suggestion"

export default class extends Controller {
  static targets = [ "timeZone" ]
  static values = { profileTimeZone: String, userId: Number }

  connect() {
    this.detectedTimeZone = browserTimeZone()
    if (!this.detectedTimeZone || this.detectedTimeZone === this.profileTimeZoneValue || this.dismissed()) return

    this.timeZoneTarget.value = this.detectedTimeZone
    this.element.hidden = false
  }

  dismiss() {
    try {
      window.localStorage.setItem(this.dismissalKey, this.timeZonePair)
    } catch (error) {
      console.error("Could not remember the dismissed time zone suggestion", error)
      // Some privacy settings prevent local storage. The suggestion remains safe to show again.
    }

    this.element.hidden = true
  }

  get dismissalKey() {
    return `${dismissalKeyPrefix}.${this.userIdValue}`
  }

  get timeZonePair() {
    return `${this.profileTimeZoneValue}:${this.detectedTimeZone}`
  }

  dismissed() {
    try {
      return window.localStorage.getItem(this.dismissalKey) === this.timeZonePair
    } catch (error) {
      console.error("Could not read the dismissed time zone suggestion", error)
      return false
    }
  }
}
