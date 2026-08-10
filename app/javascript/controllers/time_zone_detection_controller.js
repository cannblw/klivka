import { Controller } from "@hotwired/stimulus"
import { browserTimeZone } from "lib/browser_time_zone"

export default class extends Controller {
  static targets = [ "input" ]

  connect() {
    const timeZone = browserTimeZone()
    if (timeZone) this.inputTarget.value = timeZone
  }
}
