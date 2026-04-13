import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  copy() {
    const url = window.location.href

    if (navigator.clipboard) {
      navigator.clipboard.writeText(url).then(() => this.#flash())
    } else {
      const el = document.createElement("textarea")
      el.value = url
      el.style.position = "fixed"
      el.style.opacity = "0"
      document.body.appendChild(el)
      el.select()
      document.execCommand("copy")
      document.body.removeChild(el)
      this.#flash()
    }
  }

  #flash() {
    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = "コピーしました！"
    setTimeout(() => { this.buttonTarget.textContent = original }, 2000)
  }
}
