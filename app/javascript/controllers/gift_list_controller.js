import { Controller } from "@hotwired/stimulus"
import {
  attachClosestEdge,
  autoScrollWindowForElements,
  combine,
  draggable,
  dropTargetForElements,
  extractClosestEdge,
  monitorForElements,
  pointerOutsideOfPreview,
  setCustomNativeDragPreview
} from "@atlaskit/pragmatic-drag-and-drop"

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
    this.setupDragAndDrop()
  }

  disconnect() {
    this.dragAndDropCleanup?.()
    this.clearDropIndicator()
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
    this.setupDragAndDrop()
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
      this.setupDragAndDrop()
    }

    this.markChanged()
  }

  moveWithKeyboard(event) {
    if (!["ArrowUp", "ArrowDown"].includes(event.key)) return

    const item = event.currentTarget.closest('[data-gift-list-target="item"]')
    const items = this.itemTargets
    const currentIndex = items.indexOf(item)
    const nextIndex = event.key === "ArrowUp" ? currentIndex - 1 : currentIndex + 1
    if (nextIndex < 0 || nextIndex >= items.length) return

    event.preventDefault()
    const adjacentItem = items[nextIndex]

    if (event.key === "ArrowUp") {
      this.listTarget.insertBefore(item, adjacentItem)
    } else {
      this.listTarget.insertBefore(adjacentItem, item)
    }

    this.renumber()
    event.currentTarget.focus()
    this.announcePosition(nextIndex)
    this.markChanged()
  }

  setupDragAndDrop() {
    this.dragAndDropCleanup?.()

    const itemBindings = this.itemTargets.flatMap((item) => [
      this.bindDraggable(item),
      this.bindDropTarget(item)
    ])

    this.dragAndDropCleanup = combine(
      ...itemBindings,
      monitorForElements({
        canMonitor: ({ source }) => source.data.giftList === this.element,
        onDropTargetChange: ({ location, source }) => this.updateDropIndicator(location, source),
        onDrag: ({ location, source }) => this.updateDropIndicator(location, source),
        onDrop: ({ location, source }) => this.dropItem(location, source)
      }),
      autoScrollWindowForElements({
        canScroll: ({ source }) => source.data.giftList === this.element,
        getAllowedAxis: () => "vertical"
      })
    )
  }

  bindDraggable(item) {
    const handle = item.querySelector('[data-gift-list-target="handle"]')

    return draggable({
      element: item,
      dragHandle: handle,
      getInitialData: () => ({ giftList: this.element }),
      onGenerateDragPreview: ({ nativeSetDragImage }) => {
        setCustomNativeDragPreview({
          nativeSetDragImage,
          getOffset: pointerOutsideOfPreview({ x: "16px", y: "8px" }),
          render: ({ container }) => this.renderDragPreview(container, item)
        })
      },
      onDragStart: () => item.classList.add("border-dashed", "opacity-40"),
      onDrop: () => item.classList.remove("border-dashed", "opacity-40")
    })
  }

  bindDropTarget(item) {
    return dropTargetForElements({
      element: item,
      canDrop: ({ source }) => source.data.giftList === this.element,
      getData: ({ input, element }) => attachClosestEdge(
        { giftList: this.element },
        { input, element, allowedEdges: ["top", "bottom"] }
      )
    })
  }

  renderDragPreview(container, item) {
    const preview = item.cloneNode(true)
    preview.removeAttribute("data-gift-list-target")
    preview.setAttribute("aria-hidden", "true")
    preview.inert = true
    preview.classList.add("opacity-90", "shadow-xl", "ring-2", "ring-amber-400/40")
    preview.style.width = `${item.getBoundingClientRect().width}px`
    container.appendChild(preview)

    return () => preview.remove()
  }

  updateDropIndicator(location, source) {
    const target = this.currentDropTarget(location)
    const edge = target && extractClosestEdge(target.data)

    if (!target || !edge || target.element === source.element) {
      this.clearDropIndicator()
      return
    }

    if (this.dropIndicatorTarget === target.element && this.dropIndicatorEdge === edge) return

    this.clearDropIndicator()
    const indicator = document.createElement("div")
    indicator.className = `pointer-events-none absolute inset-x-0 z-10 h-0.5 rounded-full bg-amber-500 ${edge === "top" ? "-top-1.5" : "-bottom-1.5"}`
    indicator.setAttribute("aria-hidden", "true")
    target.element.appendChild(indicator)
    this.dropIndicator = indicator
    this.dropIndicatorTarget = target.element
    this.dropIndicatorEdge = edge
  }

  dropItem(location, source) {
    const originalOrder = this.itemTargets.slice()
    const target = this.currentDropTarget(location)
    const edge = target && extractClosestEdge(target.data)
    this.clearDropIndicator()

    if (!target || !edge || target.element === source.element) return

    if (edge === "top") {
      this.listTarget.insertBefore(source.element, target.element)
    } else {
      target.element.after(source.element)
    }

    const changed = originalOrder.some((item, index) => item !== this.itemTargets[index])
    if (!changed) return

    this.renumber()
    this.announcePosition(this.itemTargets.indexOf(source.element))
    this.markChanged()
  }

  currentDropTarget(location) {
    return location.current.dropTargets.find((target) => target.data.giftList === this.element)
  }

  clearDropIndicator() {
    this.dropIndicator?.remove()
    this.dropIndicator = undefined
    this.dropIndicatorTarget = undefined
    this.dropIndicatorEdge = undefined
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

  announcePosition(index) {
    this.statusTarget.textContent = this.movedMessageValue.replace("__POSITION__", index + 1)
  }

  label(template, position) {
    return template.replace("__POSITION__", position)
  }

  markChanged() {
    this.listTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
