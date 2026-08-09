import { Controller } from "@hotwired/stimulus"
import { localDateFor } from "lib/local_date"

export default class extends Controller {
  static targets = [ "source", "date" ]

  connect() {
    this.prepare()
  }

  prepare() {
    const date = localDateFor(new Date())

    this.sourceTargets.forEach((source) => { source.value = "browser" })
    this.dateTargets.forEach((dateTarget) => { dateTarget.value = date })
  }
}
