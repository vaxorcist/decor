// decor/app/javascript/controllers/tom_select_controller.js - version 1.0
// Session 54: Searchable combobox controller using the Tom Select library.
//
// Purpose:
//   Replaces any native <select data-controller="tom-select"> with a Tom Select
//   combobox that supports keyboard search, making long option lists (e.g. 400+
//   computer models) usable without knowing the exact first letter.
//
// Turbo safety:
//   connect()    — initialises Tom Select on the native <select>.
//   disconnect() — calls tomSelect.destroy(), which removes the Tom Select wrapper
//                  divs and restores the original <select> to the DOM. This is
//                  essential: Turbo caches the DOM before navigation, and without
//                  destroy() the cached snapshot contains Tom Select markup, which
//                  causes a double-initialisation error when the snapshot is restored.
//
//   Guard: if (this.element.tomselect) return — Tom Select sets this property on
//   the native element when it is active. The guard prevents double-init if
//   connect() fires twice (e.g. during Turbo morphing).
//
// Styling:
//   Tom Select's base CSS is loaded in application.html.erb (CDN link).
//   A <style> block in that same file overrides the defaults to match the project's
//   field_classes (stone-300 border, h-10 height, text-sm font, indigo focus ring).
//
// Usage:
//   <%= f.collection_select :model_id, ..., class: field_classes,
//         data: { controller: "tom-select" } %>
//
// Scope:
//   Applied to large or medium selects. NOT applied to selects that already have
//   a dedicated Stimulus controller with focus/blur actions (e.g. computer_id in
//   components/_form.html.erb uses computer-select, whose blur/focus callbacks
//   would be silenced because Tom Select hides the native element).

import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    // Guard: Tom Select sets .tomselect on the native element when active.
    // Returning early prevents double-initialisation on Turbo snapshot restore.
    if (this.element.tomselect) return

    this.tomSelect = new TomSelect(this.element, {
      // Disallow free-text entry — only pre-loaded options are valid choices.
      create: false,

      // Preserve the server-side sort order (queries already use ORDER BY name).
      // Setting sortField to false tells Tom Select not to re-sort the option list.
      sortField: false,

      // Raise the option cap well above the default (50) to handle the computer
      // model list (400+ entries) and any other long list without truncation.
      maxOptions: 1000,

      // Highlight the matched substring in the dropdown as the user types.
      highlight: true,
    })
  }

  disconnect() {
    if (this.tomSelect) {
      // destroy() removes the Tom Select wrapper divs, unhides the original
      // <select>, and removes all Tom Select event listeners. This restores
      // the DOM to its pre-init state, which Turbo can safely cache and replay.
      this.tomSelect.destroy()
      this.tomSelect = null
    }
  }
}
