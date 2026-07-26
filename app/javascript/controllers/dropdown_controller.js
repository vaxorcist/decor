// decor/app/javascript/controllers/dropdown_controller.js
// version 1.1
// Session 78: Fixed reported bug — opening one admin nav dropdown did not
//   close any other dropdown that was already open (screenshot showed all
//   nine admin dropdowns open simultaneously on /admin/owners). Root cause
//   confirmed by reading decor/app/views/layouts/admin.html.erb directly:
//   every dropdown is its own independent `data-controller="dropdown"`
//   instance with zero awareness of its siblings — there was no shared
//   state or signal connecting them at all.
//   Fix: when a dropdown is about to OPEN, it dispatches a "dropdown:open"
//   CustomEvent on `document`, carrying a reference to its own root element
//   in `detail.source`. Every dropdown instance (including the one that
//   just dispatched it) listens for this event; any instance whose root
//   element is NOT the source closes itself. This is a pure Stimulus-side
//   fix — no changes needed to admin.html.erb, since every dropdown there
//   already shares the identical `data-controller="dropdown"` structure
//   this fix relies on.
//   No new Tailwind classes, no new HTML/data attributes — existing
//   `hidden` class toggle and existing `menu` target are reused as-is.
// version 1.0
// Stimulus controller for click-to-open dropdown menus in the admin nav.
// Handles: toggle on trigger click, close on outside click.
// Each dropdown is an independent controller instance.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  // Toggle open/closed; stopPropagation prevents the document listener
  // from immediately closing the menu we just opened.
  //
  // Session 78: before actually opening (i.e. only when we're currently
  // hidden and about to become visible), broadcast a "dropdown:open" event
  // on `document` so every OTHER open dropdown closes itself first. This
  // must happen before we toggle our own class, so that when our own
  // _closeIfNotMe listener also receives this same event, it correctly
  // finds `event.detail.source === this.element` and leaves itself alone.
  toggle(event) {
    event.stopPropagation()

    const isCurrentlyHidden = this.menuTarget.classList.contains("hidden")
    if (isCurrentlyHidden) {
      document.dispatchEvent(
        new CustomEvent("dropdown:open", { detail: { source: this.element } })
      )
    }

    this.menuTarget.classList.toggle("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }

  // Store bound references so disconnect() removes the exact same function
  // instances — avoids listener leaks across Turbo navigations.
  connect() {
    this._boundClickOutside = this._clickOutside.bind(this)
    this._boundCloseOthers = this._closeIfNotMe.bind(this)
    document.addEventListener("click", this._boundClickOutside)
    document.addEventListener("dropdown:open", this._boundCloseOthers)
  }

  disconnect() {
    document.removeEventListener("click", this._boundClickOutside)
    document.removeEventListener("dropdown:open", this._boundCloseOthers)
  }

  _clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  // Session 78 (NEW): shared "close others" handler. Every dropdown
  // instance on the page receives every "dropdown:open" event (they all
  // listen on the same `document` target). An instance closes itself
  // unless it was the one that just dispatched the event — this is how a
  // newly-opened dropdown causes all its siblings to close, with no direct
  // reference between controller instances required.
  _closeIfNotMe(event) {
    if (event.detail.source !== this.element) {
      this.close()
    }
  }
}
