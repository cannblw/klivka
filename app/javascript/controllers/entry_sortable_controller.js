import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "handle", "status"]
  static values = { reorderUrl: String, errorMessage: String }

  connect() {
    this.boundStart = this.start.bind(this)
    this.element.addEventListener("pointerdown", this.boundStart)
  }

  disconnect() {
    this.element.removeEventListener("pointerdown", this.boundStart)
    this.stopTracking()
  }

  start(event) {
    if (event.button !== 0 || this.saving) return

    const handle = event.target.closest('[data-entry-sortable-target="handle"]')
    if (!handle || !this.element.contains(handle)) return

    this.draggedItem = handle.closest('[data-entry-sortable-target="item"]')
    this.list = this.draggedItem.parentElement
    this.originalOrder = this.itemTargets.slice()
    this.moved = false
    this.saving = false
    this.statusTarget.textContent = ""

    event.preventDefault()
    handle.setPointerCapture?.(event.pointerId)
    this.draggedItem.classList.add("opacity-50")
    this.pointerMove = this.move.bind(this)
    this.pointerEnd = this.finish.bind(this)
    window.addEventListener("pointermove", this.pointerMove)
    window.addEventListener("pointerup", this.pointerEnd)
    window.addEventListener("pointercancel", this.pointerEnd)
  }

  move(event) {
    if (!this.draggedItem) return

    const otherItems = this.itemTargets.filter((item) => item !== this.draggedItem)
    const before = otherItems.find((item) => {
      const rectangle = item.getBoundingClientRect()
      return event.clientY < rectangle.top + rectangle.height / 2
    })

    if (before) {
      this.list.insertBefore(this.draggedItem, before)
    } else {
      this.list.appendChild(this.draggedItem)
    }

    this.moved = true
  }

  finish(event) {
    if (!this.draggedItem) return

    this.stopTracking()
    this.draggedItem.classList.remove("opacity-50")
    const originalOrder = this.originalOrder
    const cancelled = event.type === "pointercancel"
    const changed = !cancelled && this.moved && originalOrder.some((item, index) => item !== this.itemTargets[index])

    if (cancelled) originalOrder.forEach((item) => this.list.appendChild(item))
    this.draggedItem = undefined

    if (changed) this.saveOrder(originalOrder)
  }

  stopTracking() {
    if (this.pointerMove) window.removeEventListener("pointermove", this.pointerMove)
    if (this.pointerEnd) {
      window.removeEventListener("pointerup", this.pointerEnd)
      window.removeEventListener("pointercancel", this.pointerEnd)
    }
    this.pointerMove = undefined
    this.pointerEnd = undefined
  }

  async saveOrder(originalOrder) {
    this.saving = true

    try {
      const response = await fetch(this.reorderUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ entry_ids: this.itemTargets.map((item) => item.dataset.entryId) })
      })

      if (!response.ok) throw new Error("reorder failed")
    } catch (_error) {
      originalOrder.forEach((item) => this.list.appendChild(item))
      this.statusTarget.textContent = this.errorMessageValue
    } finally {
      this.saving = false
    }
  }
}
