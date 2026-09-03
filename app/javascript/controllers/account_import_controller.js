import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "confirmButton", "error", "previewButton", "review", "summary" ]
  static values = { previewUrl: String, retryError: String }

  fileChanged(event) {
    if (event.target.type !== "file") return

    this.resetReview()
  }

  async preview() {
    this.hideError()
    this.previewButtonTarget.disabled = true
    const fileInput = this.element.querySelector("input[type='file']")
    const formData = new FormData()
    if (fileInput?.files[0]) formData.append(fileInput.name, fileInput.files[0])

    try {
      const response = await fetch(this.previewUrlValue, {
        method: "POST",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        }
      })
      if (response.redirected) {
        this.showError(this.retryErrorValue)
        this.reviewTarget.hidden = true
        return
      }

      const contentType = response.headers.get("Content-Type") || ""
      if (!contentType.includes("application/json")) {
        this.showError(this.retryErrorValue)
        this.reviewTarget.hidden = true
        return
      }

      const result = await response.json()

      if (!response.ok) {
        this.showError(result.error)
        this.reviewTarget.hidden = true
        return
      }

      this.summaryTargets.forEach((element) => {
        element.textContent = result.summary[element.dataset.summaryKey]
      })
      this.reviewTarget.hidden = false
      this.updateConfirmation()
    } catch (error) {
      console.error("Account import preview request failed", error)
      this.showError(this.retryErrorValue)
      this.reviewTarget.hidden = true
    } finally {
      this.previewButtonTarget.disabled = false
    }
  }

  async import(event) {
    event.preventDefault()
    const submitButton = document.getElementById("account-import-dialog-confirm")
    if (submitButton) submitButton.disabled = true
    this.hideError()

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        body: new FormData(this.element),
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        }
      })

      if (response.redirected || !(response.headers.get("Content-Type") || "").includes("application/json")) {
        this.showImportError(this.retryErrorValue)
        return
      }

      const result = await response.json()
      if (!response.ok) {
        this.showImportError(result.error)
        return
      }

      window.location.assign(result.redirect_url)
    } catch (error) {
      console.error("Account import request failed", error)
      this.showImportError(this.retryErrorValue)
    } finally {
      if (submitButton) submitButton.disabled = false
    }
  }

  confirm() {
    document.getElementById("account-import-dialog")?.showModal()
  }

  resetReview() {
    this.reviewTarget.hidden = true
    this.confirmButtonTarget.disabled = true
    const dialog = document.getElementById("account-import-dialog")
    if (dialog?.open) dialog.close()
    const password = document.getElementById("account-import-dialog-password")
    if (password) password.value = ""
    const importError = document.getElementById("account-import-dialog-error")
    if (importError) {
      importError.textContent = ""
      importError.hidden = true
    }
    this.hideError()
  }

  updateConfirmation() {
    this.confirmButtonTarget.disabled = this.reviewTarget.hidden
  }

  showError(message) {
    this.errorTarget.textContent = message || this.retryErrorValue
    this.errorTarget.hidden = false
  }

  hideError() {
    this.errorTarget.textContent = ""
    this.errorTarget.hidden = true
  }

  showImportError(message) {
    const error = document.getElementById("account-import-dialog-error")
    if (!error) return

    error.textContent = message || this.retryErrorValue
    error.hidden = false
  }
}
