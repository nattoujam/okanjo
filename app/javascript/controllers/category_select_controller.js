import { Controller } from "@hotwired/stimulus"

const NEW_CATEGORY = "__new__"

export default class extends Controller {
  static targets = ["select", "newName"]

  connect() {
    this.newNameTarget.hidden = !this.#creating
  }

  toggle() {
    this.newNameTarget.hidden = !this.#creating

    if (this.#creating) {
      this.newNameTarget.focus()
    } else {
      this.newNameTarget.value = ""
    }
  }

  get #creating() {
    return this.selectTarget.value === NEW_CATEGORY
  }
}
