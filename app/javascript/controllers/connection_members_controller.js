// decor/app/javascript/controllers/connection_members_controller.js
// version 1.0
// Session 36: Part 4 — Owner ConnectionGroup CRUD.
//
// Stimulus controller for dynamic add/remove of connection member rows in the
// connection group form.
//
// Targets:
//   membersList  — the container <div> that holds member rows.
//   template     — the <template> element containing the HTML for a blank row.
//
// Actions:
//   add(event)    — clones the template, replaces NEW_INDEX with Date.now() to
//                   produce a unique nested-attributes key, and appends the new
//                   row to membersList.
//   remove(event) — finds the enclosing [data-member-row] element.
//                   If the row has a [data-destroy-field] hidden input (i.e. it
//                   is a persisted record), sets its value to "1" and hides the
//                   row so Rails will destroy the record on save.
//                   If no destroy field exists (a newly added, unsaved row),
//                   removes the element from the DOM entirely.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["membersList", "template"]

  // Clone the template and append a new blank member row.
  add(event) {
    event.preventDefault()
    // Replace the NEW_INDEX placeholder with a timestamp-based unique key.
    // Rails accepts any string as a nested-attributes key; uniqueness is what
    // matters (prevents different new rows from colliding).
    const content = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, Date.now())
    this.membersListTarget.insertAdjacentHTML("beforeend", content)
  }

  // Remove a member row — either by marking it for destruction (persisted rows)
  // or by removing the DOM element (new, unsaved rows).
  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-member-row]")
    if (!row) return

    const destroyField = row.querySelector("[data-destroy-field]")
    if (destroyField) {
      // Persisted record: set _destroy to "1" so Rails destroys it on save,
      // then hide the row from the user.
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      // Unsaved row: simply remove it from the DOM.
      row.remove()
    }
  }
}
