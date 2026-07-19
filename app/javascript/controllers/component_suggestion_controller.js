// decor/app/javascript/controllers/component_suggestion_controller.js
// version 1.1
// v1.1 (Session 68): Edit Component UI changes (three confirmed changes):
//   1. Auto-accept-on-single-match REMOVED. Previously, narrowing to exactly
//      one match auto-filled the fields and moved focus to the serial number
//      input without waiting for the user to press Enter. This is now
//      treated the same as any other match count: the dropdown renders, the
//      first (only) item is highlighted, and the user must press Enter (or
//      click the item) to accept it. Typing a full/exact suggestion no
//      longer silently jumps the user to the next field.
//   2. Dropdown is now viewport-aware. Endpoint limit raised to 100
//      (component_suggestions_controller.rb v1.1), so up to 100 rows can
//      render. Rather than a fixed Tailwind max-h-* class (removed from
//      the <ul> in components/_form.html.erb v1.10), _renderDropdown()
//      computes available space between the input and the bottom of the
//      viewport and sets an inline max-height so the dropdown (a) shows
//      roughly 7-10 rows before scrolling under normal conditions, and
//      (b) never extends past the bottom edge of the page/viewport.
//   3. Bracket format changed. Suggestion rows previously showed
//      "order_number  —  description  —  [category]". Now description and
//      category are combined into a single bracketed group:
//      "order_number  (description | category)" — using "|" as the
//      separator between description and category only when a category is
//      present. See _renderDropdown() for the exact assembly logic.
//
// Purpose:
//   Fires a debounced fetch to GET /component_suggestions?query=<prefix> as the
//   user types in the order_number input. Renders a keyboard-navigable dropdown
//   styled to match Tom Select. On explicit accept (Enter or click — never
//   automatically), pre-fills order_number and description, sets the hidden
//   order_number_verified flag to "true", and moves focus to the component
//   serial number input.
//
// Targets:
//   orderNumberInput  — the order_number text input (source of the query)
//   descriptionInput  — the description text area (pre-filled on accept)
//   serialNumberInput — the component serial number input (focus destination on accept)
//   verifiedFlag      — hidden input for order_number_verified (set to "true" on accept)
//   dropdown          — the <ul> container rendered by this controller
//
// Values:
//   url (String) — the JSON endpoint URL, supplied via data-component-suggestion-url-value
//
// Keyboard:
//   ArrowDown / ArrowUp — move highlighted item (wraps top/bottom)
//   Enter               — accept highlighted item (the ONLY way a match is accepted,
//                          along with a direct click — see v1.1 change #1 above)
//   Escape              — close dropdown without accepting
//
// Turbo safety:
//   connect()    — attaches the outside-click handler and ensures clean state.
//   disconnect() — removes the outside-click handler; dropdown is DOM-local so
//                  no further cleanup is needed (Turbo replaces the frame).
//
// Free-text behaviour:
//   When a fetch returns zero results the dropdown closes but the typed value
//   is kept. order_number_verified stays "false" (its initial state from the
//   hidden field). The user may continue typing freely.
//
// Description pre-fill:
//   Accepting a suggestion fills the description input ONLY if description is
//   currently blank. This prevents overwriting a description the user already
//   typed before interacting with the dropdown. (order_number_verified is still
//   set to true regardless — it records that the order_number was validated,
//   not that the description came from the suggestion.)

import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_DELAY = 250  // milliseconds

// Desired dropdown height under normal conditions (plenty of room below the
// input): enough to show roughly 7-10 rows before the user needs to scroll.
// Rows render at ~36px tall (py-2 + text-sm line-height), so 8 rows ≈ 288px.
// This mirrors the previous static "max-h-60" (240px) closely while being a
// little roomier now that up to 100 results can come back.
const PREFERRED_MAX_HEIGHT = 288  // pixels

// Never let the dropdown's bottom edge go past the viewport bottom. This much
// breathing room is kept between the dropdown's bottom edge and the viewport
// edge so it doesn't touch the very bottom of the browser window.
const VIEWPORT_BOTTOM_MARGIN = 8  // pixels

// Floor so the dropdown is never squeezed down to an unusably short strip
// when the input happens to sit very close to the bottom of the viewport.
const MIN_DROPDOWN_HEIGHT = 100  // pixels

export default class extends Controller {
  static targets = ["orderNumberInput", "descriptionInput", "serialNumberInput", "verifiedFlag", "dropdown"]
  static values  = { url: String }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  connect() {
    // Bind the outside-click handler once and keep a reference so we can
    // remove exactly this function in disconnect().
    this._handleOutsideClick = this._onOutsideClick.bind(this)
    document.addEventListener("click", this._handleOutsideClick)

    // Index of the currently highlighted dropdown item (-1 = none highlighted).
    this._highlightedIndex = -1

    // Pending debounce timer handle.
    this._debounceTimer = null
  }

  disconnect() {
    document.removeEventListener("click", this._handleOutsideClick)
    this._clearDebounce()
  }

  // ─── Input handler — fired by data-action="input->component-suggestion#onInput" ──

  onInput() {
    this._clearDebounce()
    const query = this.orderNumberInputTarget.value.trim()

    if (query.length === 0) {
      // Clear the verified flag when the user empties the field.
      this._setVerified(false)
      this._closeDropdown()
      return
    }

    // Debounce: wait DEBOUNCE_DELAY ms after the last keystroke before fetching.
    this._debounceTimer = setTimeout(() => this._fetchSuggestions(query), DEBOUNCE_DELAY)
  }

  // ─── Keyboard handler — fired by data-action="keydown->component-suggestion#onKeydown" ──

  onKeydown(event) {
    // Only act when the dropdown is open and has items.
    if (!this._isDropdownOpen()) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this._moveHighlight(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this._moveHighlight(-1)
        break
      case "Enter":
        event.preventDefault()
        this._acceptHighlighted()
        break
      case "Escape":
        this._closeDropdown()
        break
    }
  }

  // ─── Private: fetch ────────────────────────────────────────────────────────

  async _fetchSuggestions(query) {
    const url = `${this.urlValue}?query=${encodeURIComponent(query)}`

    let suggestions
    try {
      const response = await fetch(url, {
        headers: {
          "Accept": "application/json",
          // Send the CSRF token so the session cookie is validated.
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content ?? ""
        },
        credentials: "same-origin"
      })
      if (!response.ok) return
      suggestions = await response.json()
    } catch (_err) {
      // Network error — close dropdown silently.
      this._closeDropdown()
      return
    }

    if (suggestions.length === 0) {
      // No matches: keep what the user typed, close dropdown, clear verified flag.
      this._setVerified(false)
      this._closeDropdown()
      return
    }

    // v1.1: no more auto-accept when the list narrows to exactly one match.
    // Every match count (including exactly one) renders the dropdown and
    // highlights the first item; the user must press Enter or click to
    // accept. This applies uniformly regardless of how many results came back.
    this._renderDropdown(suggestions)
    this._setHighlight(0)
  }

  // ─── Private: dropdown rendering ──────────────────────────────────────────

  // Renders the suggestion list and caches the raw suggestion objects on the
  // controller (this._suggestions) so _acceptHighlighted() can retrieve the
  // full object by index rather than re-parsing rendered DOM text.
  _renderDropdown(suggestions) {
    this._suggestions = suggestions
    this._highlightedIndex = -1
    const ul = this.dropdownTarget
    ul.innerHTML = ""

    suggestions.forEach((s, index) => {
      const li = document.createElement("li")
      li.dataset.index = index

      // Build display text: order_number is always present. Description and
      // category are combined into a single bracketed group — "|" separates
      // them only when both are present; the bracket is omitted entirely if
      // neither is present.
      //   "DELQA-00  (Ethernet controller | Networking)"  — both present
      //   "DELQA-00  (Ethernet controller)"                — description only
      //   "DELQA-00  (Networking)"                         — category only
      //   "DELQA-00"                                       — neither present
      const parts = [s.order_number]
      const bracketParts = []
      if (s.description) bracketParts.push(s.description)
      if (s.category)    bracketParts.push(s.category)
      if (bracketParts.length > 0) parts.push(`(${bracketParts.join(" | ")})`)

      li.textContent = parts.join("  ")

      // Styling mirrors Tom Select option items: same text size, padding,
      // cursor, and hover colour. The highlighted class is applied by
      // _setHighlight() via _applyHighlightStyle().
      li.className = [
        "px-3 py-2 text-sm cursor-pointer",
        "text-stone-900 hover:bg-indigo-50"
      ].join(" ")

      li.addEventListener("mousedown", (e) => {
        // Use mousedown (not click) so this fires before the input's blur event,
        // which would otherwise close the dropdown before the click registers.
        e.preventDefault()
        this._accept(s)
      })

      ul.appendChild(li)
    })

    ul.classList.remove("hidden")
    this._applyViewportAwareHeight(ul)
  }

  // Computes and applies an inline max-height so the dropdown (a) shows a
  // reasonable number of rows before needing to scroll, and (b) never
  // extends past the bottom edge of the viewport, regardless of how many of
  // the (now up to 100) results came back.
  _applyViewportAwareHeight(ul) {
    const inputRect = this.orderNumberInputTarget.getBoundingClientRect()
    const availableSpace = window.innerHeight - inputRect.bottom - VIEWPORT_BOTTOM_MARGIN

    const maxHeight = Math.max(
      MIN_DROPDOWN_HEIGHT,
      Math.min(PREFERRED_MAX_HEIGHT, availableSpace)
    )

    ul.style.maxHeight = `${maxHeight}px`
    ul.style.overflowY = "auto"
  }

  _closeDropdown() {
    this.dropdownTarget.innerHTML = ""
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.style.maxHeight = ""
    this._highlightedIndex = -1
  }

  _isDropdownOpen() {
    return !this.dropdownTarget.classList.contains("hidden") &&
           this.dropdownTarget.children.length > 0
  }

  // ─── Private: keyboard navigation ─────────────────────────────────────────

  _moveHighlight(delta) {
    const items = this.dropdownTarget.querySelectorAll("li")
    if (items.length === 0) return

    // Remove highlight from current item.
    if (this._highlightedIndex >= 0) {
      this._applyHighlightStyle(items[this._highlightedIndex], false)
    }

    // Compute new index with wrap-around.
    this._highlightedIndex = (this._highlightedIndex + delta + items.length) % items.length
    const highlighted = items[this._highlightedIndex]
    this._applyHighlightStyle(highlighted, true)
    // Keep the highlighted item visible when navigating past the edge of the
    // currently-scrolled viewport of a long (up to 100-row) dropdown.
    highlighted.scrollIntoView({ block: "nearest" })
  }

  _setHighlight(index) {
    const items = this.dropdownTarget.querySelectorAll("li")
    if (items.length === 0) return
    if (this._highlightedIndex >= 0 && this._highlightedIndex < items.length) {
      this._applyHighlightStyle(items[this._highlightedIndex], false)
    }
    this._highlightedIndex = index
    this._applyHighlightStyle(items[this._highlightedIndex], true)
  }

  _applyHighlightStyle(li, highlighted) {
    if (highlighted) {
      // Indigo-100 background to match Tom Select's active-option colour.
      li.classList.add("bg-indigo-100")
      li.classList.remove("hover:bg-indigo-50")
    } else {
      li.classList.remove("bg-indigo-100")
      li.classList.add("hover:bg-indigo-50")
    }
  }

  _acceptHighlighted() {
    const items = this.dropdownTarget.querySelectorAll("li")
    if (this._highlightedIndex < 0 || this._highlightedIndex >= items.length) return

    // Retrieve the suggestion data from the rendered text is fragile — instead,
    // we store the suggestion objects on the controller when rendering.
    // Re-use _suggestions cache set during _renderDropdown.
    if (this._suggestions && this._suggestions[this._highlightedIndex]) {
      this._accept(this._suggestions[this._highlightedIndex])
    }
  }

  // ─── Private: accept a suggestion (Enter or click ONLY — never automatic) ──

  _accept(suggestion) {
    // Fill the order_number field with the accepted value.
    this.orderNumberInputTarget.value = suggestion.order_number

    // Pre-fill description only when it is currently blank, to avoid overwriting
    // a description the user has already typed manually.
    if (suggestion.description && this.descriptionInputTarget.value.trim() === "") {
      this.descriptionInputTarget.value = suggestion.description
    }

    // Mark the order number as verified (came from the suggestions table).
    this._setVerified(true)

    this._closeDropdown()

    // Move focus to the serial number field so the user can continue entering
    // data without reaching for the mouse.
    this.serialNumberInputTarget.focus()
  }

  _setVerified(verified) {
    this.verifiedFlagTarget.value = verified ? "true" : "false"
  }

  // ─── Private: outside-click to close ──────────────────────────────────────

  _onOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this._closeDropdown()
    }
  }

  // ─── Private: debounce helpers ─────────────────────────────────────────────

  _clearDebounce() {
    if (this._debounceTimer !== null) {
      clearTimeout(this._debounceTimer)
      this._debounceTimer = null
    }
  }

}
