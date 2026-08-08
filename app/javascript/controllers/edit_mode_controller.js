import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["switch"]
  static values = { storageKey: String }

  connect() {
    this.switchTarget.checked = sessionStorage.getItem(this.storageKeyValue) === "true"
  }

  persist() {
    sessionStorage.setItem(this.storageKeyValue, this.switchTarget.checked)
  }
}
