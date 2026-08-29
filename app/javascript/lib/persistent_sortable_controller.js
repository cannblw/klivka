import { Controller } from "@hotwired/stimulus"
import { createSortable } from "lib/sortable"

export default class extends Controller {
  static targets = ["item", "status"]
  static values = { reorderUrl: String, errorMessage: String, movedMessage: String }

  connect() {
    this.sortable = createSortable({
      container: this.itemTargets[0]?.parentElement,
      getItems: () => this.itemTargets,
      getHandle: (item) => item.querySelector(this.targetSelector("handle")),
      getDropTarget: (item) => item.querySelector(this.targetSelector("dropTarget")),
      canDrag: () => !this.saving,
      onReorder: (result) => this.saveOrder(result)
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  moveWithKeyboard(event) {
    this.sortable.moveWithKeyboard(event)
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
        body: JSON.stringify({ [this.orderParameter]: currentOrder.map((item) => this.itemId(item)) })
      })

      if (!response.ok) throw new Error("reorder failed")
    } catch (error) {
      console.error(this.saveErrorMessage, error)
      restore()
      this.statusTarget.textContent = this.errorMessageValue
    } finally {
      this.saving = false
    }
  }

  targetSelector(target) {
    return `[data-${this.identifier}-target="${target}"]`
  }
}
