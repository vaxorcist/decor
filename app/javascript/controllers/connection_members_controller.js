// decor/app/javascript/controllers/connection_members_controller.js
// version 1.1
// v1.1 (Session 38): add() now pre-fills the owner_member_id field in the new
//   row with the next available port number.
//   Algorithm: scan all visible member rows for [data-owner-member-id] values
//   (the rendered existing rows carry this attribute), plus any already-filled
//   owner_member_id inputs in dynamically added rows, take the max, add 1.
//   This mirrors the server-side auto_assign_owner_member_id callback and gives
//   the user an immediate suggested value they can override before saving.
// v1.0 (Session 36): Initial Stimulus controller — add/remove member rows.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["membersList", "template"]

  // Clone the template, assign a unique nested-attributes key, pre-fill the
  // owner_member_id field with the next suggested port number, and append the
  // new row to the members list.
  add(event) {
    event.preventDefault()

    // Unique key for the nested-attributes hash (Rails accepts any string).
    const timestamp = Date.now()
    const content = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, timestamp)

    // Insert the new row HTML into the DOM before reading it back — we need
    // the actual input element to set its value.
    this.membersListTarget.insertAdjacentHTML("beforeend", content)

    // Find the just-inserted row (last child of membersList).
    const newRow = this.membersListTarget.lastElementChild

    // Pre-fill the owner_member_id input with max(existing) + 1.
    const nextId = this.nextOwnerMemberId()
    const idField = newRow.querySelector("input[name*='owner_member_id']")
    if (idField) idField.value = nextId
  }

  // Remove a member row — mark persisted rows for destruction, delete new rows.
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
      // Unsaved row: remove from the DOM immediately.
      row.remove()
    }
  }

  // Returns the next available owner_member_id: max of all visible rows + 1.
  //
  // Two sources are checked:
  //   1. data-owner-member-id attributes on rendered existing rows (set in ERB).
  //   2. owner_member_id input values in dynamically added rows (may be
  //      user-edited since insertion).
  //
  // Visible-only: hidden rows (_destroy = "1") are excluded so destroyed ports
  // don't inflate the next suggested ID unnecessarily.
  nextOwnerMemberId() {
    let max = 0

    this.membersListTarget.querySelectorAll("[data-member-row]").forEach(row => {
      // Skip rows that have been marked for destruction (hidden).
      if (row.style.display === "none") return

      // Source 1: data attribute set by ERB on persisted rows.
      const dataVal = parseInt(row.dataset.ownerMemberId, 10)
      if (!isNaN(dataVal) && dataVal > max) max = dataVal

      // Source 2: input field value (covers newly added rows whose ID may have
      // been edited by the user after insertion).
      const input = row.querySelector("input[name*='owner_member_id']")
      if (input) {
        const inputVal = parseInt(input.value, 10)
        if (!isNaN(inputVal) && inputVal > max) max = inputVal
      }
    })

    return max + 1
  }
}
