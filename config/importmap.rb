# decor/config/importmap.rb - version 1.1
# v1.1 (Session 54): Pinned tom-select for the searchable combobox Stimulus controller.
#   ESM build is required for importmap compatibility (importmap-rails only supports ES modules).
#   The "complete" variant includes all Tom Select plugins in one file, which avoids
#   relative-import issues that can occur with the modular ESM build on CDN.

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Tom Select — searchable combobox that replaces native <select> elements.
# Used by the TomSelectController Stimulus controller (tom_select_controller.js).
# ESM "complete" build: all plugins bundled, single file, no internal relative imports.
pin "tom-select", to: "https://cdn.jsdelivr.net/npm/tom-select@2.3.1/dist/esm/tom-select.complete.min.js"
