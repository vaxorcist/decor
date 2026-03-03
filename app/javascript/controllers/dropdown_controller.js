// decor/app/javascript/controllers/dropdown_controller.js
// version 1.0
// Stimulus controller for click-to-open dropdown menus in the admin nav.
// Handles: toggle on trigger click, close on outside click.
// Each dropdown is an independent controller instance.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  // Toggle open/closed; stopPropagation prevents the document listener
  // from immediately closing the menu we just opened.
  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }

  // Store bound reference so disconnect() removes the exact same function
  // instance — avoids listener leaks across Turbo navigations.
  connect() {
    this._boundClickOutside = this._clickOutside.bind(this)
    document.addEventListener("click", this._boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this._boundClickOutside)
  }

  _clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
