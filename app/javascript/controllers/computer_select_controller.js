// decor/app/javascript/controllers/computer_select_controller.js - version 1.1
// Stimulus controller for the Computer Model dropdown on the component new/edit form.
//
// Responsibilities:
//   1. Auto-fill the read-only Computer Order Number and Serial Number display
//      fields whenever the user picks a computer (or when the edit page loads
//      with a computer already selected).
//   2. Display behaviour of the <select> itself:
//      - While browsing (dropdown open): each option shows full detail —
//        "Model  /  Order Number  /  Serial Number" — so the user can identify
//        the right computer before committing to a choice.
//      - After a computer is selected (dropdown closed): the select field shows
//        the model name only, because Order Number and Serial Number are already
//        visible in the dedicated read-only display fields next to it.
//      - The blank "Spare (not attached)" option is left untouched throughout.
//
// Data flow:
//   - Each <option> (except blank) carries:
//       data-model-name  — the model name alone (used for the collapsed display)
//       data-full-label  — set once on connect() from the option's initial text
//                          (used to restore the full label when the dropdown opens)
//   - A JSON map { computer_id => { order_number, serial_number } } is embedded
//     as a Stimulus "computers" value on the Row 1 wrapper div by the ERB template.
//
// Why no name attribute on the display inputs:
//   Computer Order Number and Serial Number belong to the Computer record, not the
//   Component. Submitting them would require the controller to ignore them anyway.
//   They are display-only context cues.
//
// Auto-registered by stimulus-rails eagerLoadControllersFrom — no index.js edit needed.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["computerSelect", "orderNumber", "serialNumber"]
  static values  = { computers: Object }

  // On connect: cache all full labels, populate display fields, collapse selected option.
  // This handles the edit page where a computer is pre-selected on load.
  connect() {
    this._cacheFullLabels()
    this._updateFields()
    this._collapseSelected()
  }

  // Fires via data-action="change->computer-select#change" on the <select>.
  change() {
    this._updateFields()
    this._collapseSelected()
  }

  // Fires via data-action="focus->computer-select#openDropdown" on the <select>.
  // Restores all options to their full "Model / Order / Serial" labels so the user
  // can read all the detail while browsing the dropdown.
  openDropdown() {
    this._restoreFullLabels()
  }

  // Fires via data-action="blur->computer-select#closeDropdown" on the <select>.
  // Re-collapses the selected option to model name only after the user dismisses
  // the dropdown (whether or not they changed the selection).
  closeDropdown() {
    this._collapseSelected()
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  // Cache each option's initial text as data-full-label once.
  // Skip the blank option (value === "").
  _cacheFullLabels() {
    Array.from(this.computerSelectTarget.options).forEach(opt => {
      if (opt.value && !opt.dataset.fullLabel) {
        opt.dataset.fullLabel = opt.text
      }
    })
  }

  // Restore all non-blank options to their full "Model / Order / Serial" label.
  _restoreFullLabels() {
    Array.from(this.computerSelectTarget.options).forEach(opt => {
      if (opt.value && opt.dataset.fullLabel) {
        opt.text = opt.dataset.fullLabel
      }
    })
  }

  // Collapse the currently selected option to model name only (if a computer is selected).
  // The blank "Spare" option (value === "") is left untouched.
  _collapseSelected() {
    const select = this.computerSelectTarget
    const selected = select.options[select.selectedIndex]
    if (!selected || !selected.value) return   // nothing selected, or "Spare"
    if (selected.dataset.modelName) {
      selected.text = selected.dataset.modelName
    }
  }

  // Look up the selected computer id in the embedded JSON map and write
  // order_number and serial_number into the read-only display inputs.
  // Clears both fields when "Spare" (no computer) is selected.
  _updateFields() {
    const id   = this.computerSelectTarget.value
    const data = id ? (this.computersValue[id] || {}) : {}
    this.orderNumberTarget.value  = data.order_number  || ""
    this.serialNumberTarget.value = data.serial_number || ""
  }
}
