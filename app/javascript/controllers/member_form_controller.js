import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameInput", "memberList", "fields"]

  connect() {
    this.index = 0
  }

  addMember() {
    const name = this.nameInputTarget.value.trim()
    if (!name) return

    this.#appendListItem(name)
    this.#appendHiddenField(name)
    this.nameInputTarget.value = ""
    this.nameInputTarget.focus()
  }

  removeMember(event) {
    const item = event.currentTarget.closest("li")
    const index = item.dataset.memberIndex
    const field = this.fieldsTarget.querySelector(`[data-member-index="${index}"]`)

    item.remove()
    field?.remove()
  }

  // Enterキーで追加できるようにする
  nameInputTargetConnected(element) {
    element.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault()
        this.addMember()
      }
    })
  }

  #appendListItem(name) {
    const li = document.createElement("li")
    li.dataset.memberIndex = this.index
    li.className = "flex items-center justify-between bg-gray-50 rounded px-3 py-1 text-sm"
    li.innerHTML = `
      <span>${this.#escapeHtml(name)}</span>
      <button type="button" class="text-black-500 hover:text-red-500 ml-2" data-action="click->member-form#removeMember">&times;</button>
    `
    this.memberListTarget.appendChild(li)
  }

  #appendHiddenField(name) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = `group[members_attributes][${this.index}][name]`
    input.value = name
    input.dataset.memberIndex = this.index
    this.fieldsTarget.appendChild(input)
    this.index++
  }

  #escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }
}
