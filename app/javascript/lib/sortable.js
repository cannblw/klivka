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

const pageDropTarget = {
  cleanup: undefined,
  users: 0
}

export function createSortable(options) {
  return new Sortable(options)
}

function acquirePageDropTarget() {
  pageDropTarget.users += 1
  pageDropTarget.cleanup ||= dropTargetForElements({
    element: document.body,
    canDrop: ({ source }) => Boolean(source.data.sortableList),
    getData: ({ source }) => ({ sortableList: source.data.sortableList })
  })

  return () => {
    pageDropTarget.users -= 1
    if (pageDropTarget.users > 0) return

    pageDropTarget.cleanup?.()
    pageDropTarget.cleanup = undefined
  }
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
      acquirePageDropTarget(),
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

  moveWithKeyboard(event) {
    if (!["ArrowUp", "ArrowDown"].includes(event.key) || !this.canDrag()) return

    const item = this.items.find((candidate) => candidate.contains(event.currentTarget))
    if (!item) return

    const offset = event.key === "ArrowUp" ? -1 : 1
    const result = this.move(item, offset)
    if (!result) return

    event.preventDefault()
    event.currentTarget.focus()
    return result
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
    preview.classList.add("opacity-90", "shadow-xl", "ring-2", "ring-brand-highlight/40")
    preview.style.width = `${item.getBoundingClientRect().width}px`
    container.appendChild(preview)

    return () => preview.remove()
  }

  updateDropIndicator(location, source) {
    const target = this.currentDropTarget(location, source)
    const edge = target && extractClosestEdge(target.data)

    if (!target || !edge || target.data.sortableItem === source.element) {
      this.clearDropIndicator()
      return
    }

    if (this.dropIndicatorTarget === target.element && this.dropIndicatorEdge === edge) return

    this.clearDropIndicator()
    const indicator = document.createElement("div")
    indicator.className = `pointer-events-none absolute inset-x-0 z-10 h-0.5 rounded-full bg-brand-focus ${edge === "top" ? "-top-1.5" : "-bottom-1.5"}`
    indicator.setAttribute("aria-hidden", "true")
    target.element.appendChild(indicator)
    this.dropIndicator = indicator
    this.dropIndicatorTarget = target.element
    this.dropIndicatorEdge = edge
  }

  dropItem(location, source) {
    const previousOrder = this.items
    const target = this.currentDropTarget(location, source)
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

  currentDropTarget(location, source) {
    const target = location.current.dropTargets.find((dropTarget) =>
      dropTarget.data.sortableList === this.listIdentity && dropTarget.data.sortableItem
    )
    if (target) return target

    const boundary = location.current.dropTargets.find((dropTarget) =>
      dropTarget.data.sortableList === this.listIdentity
    )
    if (!boundary) return

    return this.boundaryDropTarget(location, source)
  }

  boundaryDropTarget(location, source) {
    const items = this.items.filter((item) => item !== source.element)
    if (!items.length) return

    const pointerY = location.current.input.clientY
    const targetItem = items.find((item) => {
      const bounds = this.getDropTarget(item).getBoundingClientRect()
      return pointerY < bounds.top + (bounds.height / 2)
    }) || items.at(-1)
    const targetBounds = this.getDropTarget(targetItem).getBoundingClientRect()
    const edge = pointerY < targetBounds.top + (targetBounds.height / 2) ? "top" : "bottom"
    const targetElement = this.getDropTarget(targetItem)

    return {
      element: targetElement,
      data: attachClosestEdge(
        { sortableList: this.listIdentity, sortableItem: targetItem },
        { input: location.current.input, element: targetElement, allowedEdges: [edge] }
      )
    }
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
