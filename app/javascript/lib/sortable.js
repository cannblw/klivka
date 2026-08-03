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

export function createSortable(options) {
  return new Sortable(options)
}

class Sortable {
  constructor({ container, getItems, getHandle, getDropTarget, canDrag, onReorder }) {
    this.container = container
    this.getItems = getItems
    this.getHandle = getHandle
    this.getDropTarget = getDropTarget || ((item) => item)
    this.canDrag = canDrag || (() => true)
    this.onReorder = onReorder
    this.listIdentity = container
    this.refresh()
  }

  refresh() {
    this.cleanup?.()

    const itemBindings = this.items.flatMap((item) => [
      this.bindDraggable(item),
      this.bindDropTarget(item)
    ])

    this.cleanup = combine(
      ...itemBindings,
      monitorForElements({
        canMonitor: ({ source }) => this.belongsToList(source),
        onDropTargetChange: ({ location, source }) => this.updateDropIndicator(location, source),
        onDrag: ({ location, source }) => this.updateDropIndicator(location, source),
        onDrop: ({ location, source }) => this.dropItem(location, source)
      }),
      autoScrollWindowForElements({
        canScroll: ({ source }) => this.belongsToList(source),
        getAllowedAxis: () => "vertical"
      })
    )
  }

  destroy() {
    this.cleanup?.()
    this.clearDropIndicator()
  }

  move(item, offset) {
    if (!this.canDrag()) return

    const previousOrder = this.items
    const currentIndex = previousOrder.indexOf(item)
    const nextIndex = currentIndex + offset
    if (nextIndex < 0 || nextIndex >= previousOrder.length) return

    const adjacentItem = previousOrder[nextIndex]
    if (offset < 0) {
      this.container.insertBefore(item, adjacentItem)
    } else {
      this.container.insertBefore(adjacentItem, item)
    }

    return this.notifyReorder(item, previousOrder)
  }

  bindDraggable(item) {
    return draggable({
      element: item,
      dragHandle: this.getHandle(item),
      canDrag: () => this.canDrag(),
      getInitialData: () => ({ sortableList: this.listIdentity }),
      onGenerateDragPreview: ({ nativeSetDragImage }) => {
        setCustomNativeDragPreview({
          nativeSetDragImage,
          getOffset: pointerOutsideOfPreview({ x: "16px", y: "8px" }),
          render: ({ container }) => this.renderDragPreview(container, item)
        })
      },
      onDragStart: () => item.classList.add("opacity-40"),
      onDrop: () => item.classList.remove("opacity-40")
    })
  }

  bindDropTarget(item) {
    const element = this.getDropTarget(item)

    return dropTargetForElements({
      element,
      canDrop: ({ source }) => this.belongsToList(source),
      getData: ({ input, element }) => attachClosestEdge(
        { sortableList: this.listIdentity, sortableItem: item },
        { input, element, allowedEdges: ["top", "bottom"] }
      )
    })
  }

  renderDragPreview(container, item) {
    const preview = item.cloneNode(true)
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

    if (!target || !edge || target.data.sortableItem === source.element) {
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
    const previousOrder = this.items
    const target = this.currentDropTarget(location)
    const edge = target && extractClosestEdge(target.data)
    this.clearDropIndicator()

    const targetItem = target?.data.sortableItem
    if (!targetItem || !edge || targetItem === source.element) return

    if (edge === "top") {
      this.container.insertBefore(source.element, targetItem)
    } else {
      targetItem.after(source.element)
    }

    this.notifyReorder(source.element, previousOrder)
  }

  notifyReorder(item, previousOrder) {
    const currentOrder = this.items
    const changed = previousOrder.some((previousItem, index) => previousItem !== currentOrder[index])
    if (!changed) return

    const result = {
      item,
      previousOrder,
      currentOrder,
      previousIndex: previousOrder.indexOf(item),
      currentIndex: currentOrder.indexOf(item),
      restore: () => previousOrder.forEach((previousItem) => this.container.appendChild(previousItem))
    }
    this.onReorder(result)
    return result
  }

  currentDropTarget(location) {
    return location.current.dropTargets.find((target) => target.data.sortableList === this.listIdentity)
  }

  belongsToList(source) {
    return source.data.sortableList === this.listIdentity
  }

  clearDropIndicator() {
    this.dropIndicator?.remove()
    this.dropIndicator = undefined
    this.dropIndicatorTarget = undefined
    this.dropIndicatorEdge = undefined
  }

  get items() {
    return this.getItems()
  }
}
