import { Controller } from "@hotwired/stimulus"
import { createSortable } from "lib/sortable"

export default class extends Controller {
  static targets = ["list", "item", "handle", "input", "template", "status"]
  static values = {
    dragLabel: String,
    toggleLabel: String,
    inputLabel: String,
    removeLabel: String,
    movedMessage: String
  }

  connect() {
    this.nextIndex = this.itemTargets.length
    this.sortable = createSortable({
      container: this.listTarget,
      getItems: () => this.itemTargets,
      getHandle: (item) => item.querySelector('[data-gift-list-target="handle"]'),
      onReorder: ({ currentIndex }) => this.handleReorder(currentIndex)
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  add() {
    this.insertItem(this.itemTargets.length)
  }

  addAfter(event) {
    if (event.isComposing) return

    event.preventDefault()
    const item = event.currentTarget.closest('[data-gift-list-target="item"]')
    this.insertItem(this.itemTargets.indexOf(item) + 1)
  }

  insertItem(index) {
    const position = index + 1
    const html = this.templateTarget.innerHTML
      .replaceAll("__INDEX__", `new_${this.nextIndex++}`)
      .replaceAll("__POSITION__", position)

    const itemAfterInsertion = this.itemTargets[index]
    if (itemAfterInsertion) {
      itemAfterInsertion.insertAdjacentHTML("beforebegin", html)
    } else {
      this.listTarget.insertAdjacentHTML("beforeend", html)
    }

    this.renumber()
    this.sortable.refresh()
    this.inputTargets[index].focus()
    this.markChanged()
  }

  remove(event) {
    const item = event.currentTarget.closest('[data-gift-list-target="item"]')

    if (this.itemTargets.length === 1) {
      const input = item.querySelector('[data-gift-list-target="input"]')
      const checkbox = item.querySelector('input[type="checkbox"]')
      input.value = ""
      checkbox.checked = false
      input.focus()
    } else {
      item.remove()
      this.renumber()
      this.sortable.refresh()
    }

    this.markChanged()
  }

  moveWithKeyboard(event) {
    if (!["ArrowUp", "ArrowDown"].includes(event.key)) return

    const item = event.currentTarget.closest('[data-gift-list-target="item"]')
    const offset = event.key === "ArrowUp" ? -1 : 1
    const result = this.sortable.move(item, offset)
    if (!result) return

    event.preventDefault()
    event.currentTarget.focus()
  }

  handleReorder(currentIndex) {
    this.renumber()
    this.statusTarget.textContent = this.movedMessageValue.replace("__POSITION__", currentIndex + 1)
    this.markChanged()
  }

  renumber() {
    this.itemTargets.forEach((item, index) => {
      const position = index + 1
      item.querySelector('[data-gift-list-target="handle"]').ariaLabel = this.label(this.dragLabelValue, position)
      item.querySelector('input[type="checkbox"]').ariaLabel = this.label(this.toggleLabelValue, position)
      item.querySelector('[data-gift-list-target="input"]').ariaLabel = this.label(this.inputLabelValue, position)
      item.querySelector('[data-action="gift-list#remove"]').ariaLabel = this.label(this.removeLabelValue, position)
    })
  }

  label(template, position) {
    return template.replace("__POSITION__", position)
  }

  markChanged() {
    this.listTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
