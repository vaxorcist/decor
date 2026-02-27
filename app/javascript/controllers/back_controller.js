// decor/app/javascript/controllers/back_controller.js - version 1.0
// Stimulus controller for a smart "Back" button.
//
// Primary behaviour: calls history.back() so the user returns to wherever
// they came from (the referring page in browser history).
//
// Fallback behaviour: when the page was opened directly (no history — e.g.
// bookmarked, opened in a new tab, or visited as the first page), history.back()
// would do nothing. In that case the controller navigates to a fallback URL
// provided by the view via a Stimulus value.
//
// Usage in a view:
//   <a href="#"
//      data-controller="back"
//      data-back-fallback-url-value="<%= some_path %>"
//      data-action="click->back#go"
//      class="...">← Back</a>
//
// Auto-registered by stimulus-rails / eagerLoadControllersFrom — no manual
// entry in controllers/index.js required.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Declares the Stimulus Value API for the fallback URL.
  // Accessible as this.fallbackUrlValue inside the controller.
  static values = { fallbackUrl: String }

  // Called when the user clicks the Back link (data-action="click->back#go").
  go(event) {
    event.preventDefault()

    // window.history.length is 1 when this is the first (or only) page in the
    // tab's history — i.e. there is nowhere to go back to.
    if (window.history.length > 1) {
      history.back()
    } else {
      window.location.href = this.fallbackUrlValue
    }
  }
}
