import { Controller } from "@hotwired/stimulus"
import { createSortable } from "lib/sortable"

export default class extends Controller {
  static targets = ["item", "handle", "dropTarget", "status"]
  static values = { reorderUrl: String, errorMessage: String, movedMessage: String }

  connect() {
    this.sortable = createSortable({
      container: this.itemTargets[0]?.parentElement,
      getItems: () => this.itemTargets,
      getHandle: (item) => item.querySelector('[data-entry-sortable-target="handle"]'),
      getDropTarget: (item) => item.querySelector('[data-entry-sortable-target="dropTarget"]'),
      canDrag: () => !this.saving,
      onReorder: (result) => this.saveOrder(result)
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  moveWithKeyboard(event) {
    if (!["ArrowUp", "ArrowDown"].includes(event.key) || this.saving) return

    const item = event.currentTarget.closest('[data-entry-sortable-target="item"]')
    const offset = event.key === "ArrowUp" ? -1 : 1
    const result = this.sortable.move(item, offset)
    if (!result) return

    event.preventDefault()
    event.currentTarget.focus()
  }

  async saveOrder({ currentOrder, currentIndex, restore }) {
    this.saving = true
    this.statusTarget.textContent = this.movedMessageValue.replace("__POSITION__", currentIndex + 1)

    try {
      const response = await fetch(this.reorderUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ entry_ids: currentOrder.map((item) => item.dataset.entryId) })
      })

      if (!response.ok) throw new Error("reorder failed")
    } catch (error) {
      console.error("Could not save the entry order", error)
      restore()
      this.statusTarget.textContent = this.errorMessageValue
    } finally {
      this.saving = false
    }
  }
}
