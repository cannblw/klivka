import { Controller } from "@hotwired/stimulus"

const BLUR_DELAY_MILLISECONDS = 100
const ACTIVE_OPTION_CLASSES = [ "bg-amber-50", "text-amber-700", "dark:bg-amber-900/30", "dark:text-amber-400" ]

export default class extends Controller {
  static targets = [ "input", "list", "status", "form" ]
  static values = {
    url: String,
    delay: Number,
    noResults: String,
    currentCategory: String,
    results: String,
    loading: String,
    error: String
  }

  connect() {
    this.suggestions = []
    this.activeIndex = -1
  }

  disconnect() {
    window.clearTimeout(this.timeout)
    window.clearTimeout(this.blurTimeout)
    this.request?.abort()
  }

  search() {
    window.clearTimeout(this.timeout)
    this.request?.abort()
    const query = this.inputTarget.value.trim()

    if (query === "") {
      this.close()
      return
    }

    this.timeout = window.setTimeout(() => this.load(query), this.delayValue)
  }

  async load(query) {
    this.request = new AbortController()
    this.statusTarget.textContent = this.loadingValue
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("query", query)

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" }, signal: this.request.signal })
      if (!response.ok) throw new Error(`Request failed with status ${response.status}`)

      this.render(await response.json())
    } catch (error) {
      if (error.name === "AbortError") return

      console.error("Person category suggestions could not be loaded", error)
      this.statusTarget.textContent = this.errorValue
      this.renderMessage(this.errorValue)
    }
  }

  render(suggestions) {
    this.suggestions = suggestions
    this.activeIndex = -1
    this.listTarget.replaceChildren()

    if (suggestions.length === 0) {
      this.statusTarget.textContent = this.noResultsValue
      this.renderMessage(this.noResultsValue)
      return
    }

    suggestions.forEach((suggestion, index) => this.listTarget.append(this.option(suggestion, index)))
    this.statusTarget.textContent = this.resultsValue.replace("__COUNT__", suggestions.length)
    this.listTarget.classList.remove("hidden")
    this.inputTarget.setAttribute("aria-expanded", "true")
    this.activate(0)
  }

  renderMessage(message) {
    const item = document.createElement("li")
    item.className = "px-3 py-2 text-sm text-stone-500 dark:text-stone-400"
    item.textContent = message
    this.listTarget.replaceChildren(item)
    this.listTarget.classList.remove("hidden")
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  option(suggestion, index) {
    const option = document.createElement("li")
    option.id = `${this.listTarget.id}-option-${index}`
    option.role = "option"
    option.setAttribute("aria-selected", "false")
    option.className = "cursor-pointer rounded-md px-3 py-2 text-sm hover:bg-stone-100 dark:hover:bg-stone-700"
    option.addEventListener("mousedown", (event) => event.preventDefault())
    option.addEventListener("click", () => this.select(index))

    const name = document.createElement("span")
    name.className = "block font-medium"
    name.textContent = suggestion.name
    option.append(name)

    if (suggestion.category) {
      const category = document.createElement("span")
      category.className = "block text-xs text-stone-500 dark:text-stone-400"
      category.textContent = this.currentCategoryValue.replace("__CATEGORY__", suggestion.category)
      option.append(category)
    }

    return option
  }

  keydown(event) {
    if (this.suggestions.length === 0 || this.listTarget.classList.contains("hidden")) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activate((this.activeIndex + 1) % this.suggestions.length)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activate((this.activeIndex - 1 + this.suggestions.length) % this.suggestions.length)
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      this.select(this.activeIndex)
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  activate(index) {
    // Moving DOM focus into the transient list would interrupt typing, so ARIA carries the active option while focus stays in the input.
    const previousOption = this.listTarget.children[this.activeIndex]
    previousOption?.setAttribute("aria-selected", "false")
    previousOption?.classList.remove(...ACTIVE_OPTION_CLASSES)
    this.activeIndex = index
    const option = this.listTarget.children[index]
    option.setAttribute("aria-selected", "true")
    option.classList.add(...ACTIVE_OPTION_CLASSES)
    option.scrollIntoView({ block: "nearest" })
    this.inputTarget.setAttribute("aria-activedescendant", option.id)
  }

  select(index) {
    const suggestion = this.suggestions[index]
    if (!suggestion) return

    this.formTarget.action = suggestion.assignment_url
    this.formTarget.requestSubmit()
  }

  blur() {
    this.blurTimeout = window.setTimeout(() => this.close(), BLUR_DELAY_MILLISECONDS)
  }

  close() {
    this.suggestions = []
    this.activeIndex = -1
    this.closeList()
  }

  closeList() {
    this.listTarget.classList.add("hidden")
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }
}
