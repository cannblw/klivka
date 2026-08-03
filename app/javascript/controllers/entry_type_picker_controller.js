import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "empty"]

  filter(event) {
    const query = this.normalize(event.currentTarget.value.trim())
    let visibleCount = 0

    this.itemTargets.forEach((item) => {
      const visible = this.normalize(item.dataset.searchValue).includes(query)
      item.hidden = !visible
      if (visible) visibleCount += 1
    })

    this.emptyTarget.hidden = visibleCount !== 0
  }

  normalize(value) {
    return value.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLocaleLowerCase()
  }
}
