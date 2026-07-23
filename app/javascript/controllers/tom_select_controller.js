// decor/app/javascript/controllers/tom_select_controller.js - version 1.1
// v1.1 (Session 76): Fixed sortField — see the inline comment at the
//   sortField option below for the full root-cause explanation. Reported
//   symptom: the Computer Model dropdown on /computers/new was not sorted
//   alphabetically, either before or after typing to filter it. Root cause
//   was NOT the Rails-side query (computers/_form.html.erb's
//   ComputerModel.where(...).order(:name) was already correct) — it was
//   this file's `sortField: false`, which is not a valid Tom Select option
//   value and silently fell back to a JS integer-object-key enumeration
//   order (i.e. sorted by id) instead. Fixes all three selects that use
//   this controller (Computer Model, Condition, Run Status) — the smaller
//   two lists likely happened to look correct by coincidence (ids assigned
//   in roughly alphabetical creation order), which is why only the large
//   Computer Model list (400+ entries, ids assigned over time in no
//   particular relation to name) made the bug visible.
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

      // Explicitly sort dropdown options (both the full list and filtered
      // search results while typing) alphabetically by visible text.
      //
      // v1.1 fix: this was previously `sortField: false`, based on the
      // (incorrect) assumption that `false` tells Tom Select to leave the
      // server-side ORDER BY name order untouched. `sortField` is not a
      // boolean option — passing false isn't a valid configuration, so Tom
      // Select fell back to enumerating its internal options object by key.
      // Since collection_select's option VALUES are the numeric `id`s,
      // JavaScript engines always enumerate integer-like object keys in
      // ascending numeric order (per the ECMAScript spec for integer-index
      // properties) — completely ignoring both insertion order and the
      // Rails-side ORDER BY name. The result: every Tom Select dropdown was
      // silently ordered by database id, not by name, both in the closed
      // list and while filtering by typed characters (the same underlying
      // object order feeds the search results too).
      //
      // Fix: set sortField explicitly to sort by the option's visible text,
      // ascending — this is honored both for the full list and for filtered
      // search results, and doesn't depend on option value type at all.
      sortField: {
        field: "text",
        direction: "asc",
      },

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
