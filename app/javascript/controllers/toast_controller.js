import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ring"]
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.startCountdown()
    this.dismissTimeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.dismissTimeout)
  }

  dismiss() {
    clearTimeout(this.dismissTimeout)
    this.element.classList.add("opacity-0", "translate-x-2")
    setTimeout(() => this.element.remove(), 200)
  }

  startCountdown() {
    const ring = this.ringTarget
    const circumference = 2 * Math.PI * ring.r.baseVal.value

    ring.style.strokeDasharray = circumference
    ring.style.strokeDashoffset = 0
    // Flush styles so the ring animates from full instead of jumping straight to empty
    ring.getBoundingClientRect()
    ring.style.transition = `stroke-dashoffset ${this.durationValue}ms linear`
    ring.style.strokeDashoffset = circumference
  }
}
