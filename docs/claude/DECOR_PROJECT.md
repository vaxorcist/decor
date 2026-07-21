# decor/docs/claude/DECOR_PROJECT.md
# version 2.65
# Session 74: Documentation compression pass (continuing the Session 73
#   experiment, now also applied to SESSION_HANDOVER.md and RAILS_SPECIFICS.md
#   this same session — see those files' own changelogs). In this file:
#   (1) compressed the header changelog entries for Sessions 65–72 (all
#   closed-out; full detail already lives in the body sections below and in
#   SESSION_HANDOVER.md) from multi-paragraph entries down to 2–4 lines each
#   — Session 73's entry, still open, kept in full; (2) merged the two
#   back-to-back "Phase 4" sections (one marked DONE, one a fully-superseded
#   Session 66 design-pivot narrative) into one, preserving the genuinely
#   useful, non-duplicated data-format decision (order_number/description
#   concatenation with " | " delimiter) that had no other home, while
#   dropping the shelved schema-split design detail down to a pointer at
#   ORDER_NUMBER_VARIANT_DESIGN.md + SESSION_HANDOVER.md; (3) compressed two
#   fully-resolved "NOT YET DONE" checklists (Phase 4's, Owner Part Number's)
#   that had a confirmatory "all done" note bolted onto the entire original
#   checkbox list preserved "as historical record" — replaced each with a
#   short prose confirmation, since the checklist items themselves add
#   nothing once resolved and Session 72's incident detail already covers
#   what actually happened. Deliberately NOT touched: Directory Tree, Key
#   file versions table, Data Model Overview, Design Patterns, Known Issues
#   & Solutions, Quick Reference Commands — these are live reference content
#   (Pre-Implementation Verification depends on them), not duplicated
#   narrative, and compressing them the same way risked deleting the only
#   copy of real information rather than removing genuine duplication.
# Session 73: Category Help Pages feature — IMPLEMENTED (7 files: 5
#   production, 2 test; 0 migrations). 5 new owner-facing help pages (one per
#   device/software category) added entirely as data + routes on the
#   existing SiteText subsystem — no schema change. Two real bugs found and
#   fixed while implementing (both were pre-existing, unrelated to this
#   session's own additions, caught because Never-Guess required reading the
#   actual files rather than assuming the admin-only Session 20 KNOWN_TEXTS
#   refactor had been applied everywhere): (1) the owner-facing
#   SiteTextsController still had its own stale title_for_key hash that was
#   never updated to delegate to SiteText.title_for_key; (2) the admin
#   controller's url_for_key was a hardcoded case statement requiring manual
#   editing on every future SiteText key addition, generalized to a single
#   send("#{key}_path") call. Also fixed a real documentation gap flagged
#   back in Session 69/72's "!! GAP NOTICE !!" pattern: SiteText had never
#   appeared in this document's "Data Model Overview" at all despite existing
#   since Session 18 — added below. Full detail in SESSION_HANDOVER.md
#   "Session 73 Summary".
# Session 72: Confirmed by Ulli — Sessions 67–70 all already committed/pushed/
#   merged/deployed to main. This session: fixed a bundle-audit CI failure (4
#   gems), merged/deployed feature/owner_part_number. Full detail: "Owner Part
#   Number Feature — Sessions 69–72" below; SESSION_HANDOVER.md "Session 72 Summary".
# Session 71: Owner Part Number display fix (9 files). Also: the old upload-
#   collision workaround is now RESOLVED via COMMON_BEHAVIOR.md v3.0's File
#   Transfer Protocol (export/import scripts, @-encoded flat filenames).
# Session 70: Owner Part Number feature — IMPLEMENTED (11/12 files; schema.rb
#   confirmed via Session 72's db:migrate). All 3 Session 69 design questions
#   answered/implemented. Full detail: "Owner Part Number Feature — Sessions
#   69–72" below; SESSION_HANDOVER.md "Session 70 Summary".
# Session 69: UI Terminology Rename — IMPLEMENTED (15 files; see "UI
#   Terminology — Established Renames" under Design Patterns). Owner Part
#   Number — design consultation only this session, implemented Session 70.
#   Also flagged the still-open Session 68 documentation gap — see
#   SESSION_HANDOVER.md "!! GAP NOTICE !!".
# Session 67: Component Suggestions Phase 4 — IMPLEMENTED (was design-only in
#   Session 66). Manual flag + widened description migration, "Download
#   Manual Changes" export, import rewrite (delete_all + insert_all — fixed
#   the production timeout), paginated/filterable admin index. 12 production
#   + 4 test files. Full detail: "Component Suggestions Feature — Phase 4"
#   below; SESSION_HANDOVER.md "Session 67 Summary".
# Session 66: Order number / variant — design pivot, NO IMPLEMENTATION. Full
#   variant-split design specified then shelved (risk of featuritis) —
#   reference only at ORDER_NUMBER_VARIANT_DESIGN.md v1.0. Adopted simpler
#   concatenated-field approach instead (implemented Session 67). Full
#   detail: "Component Suggestions Feature — Phase 4" below.
# Session 65: Component order_number bulk maintenance — two new admin
#   Components dropdown items (Re-validate / Download Unvalidated Order
#   Numbers), 8 files. Full detail: "Component Suggestions Feature — Phase 3"
#   below; SESSION_HANDOVER.md "Session 65 Summary".
# Session 64 (wrap-up): Promoted the admin nav lesson from a changelog note to
#   a standing rule in "Known Issues & Solutions" (see that section) so future
#   sessions consult it before starting work, not just read it as history.
#
# Session 64 (continued): Admin nav fix — Component Suggestions was missing from
#   the admin menu entirely. Root cause: Session 63 Phase 1 shipped the admin
#   CRUD controller + views but never updated decor/app/views/layouts/admin.html.erb,
#   so the feature had no menu entry from day one (caught by the user after Phase 2).
#   Fix: admin.html.erb v2.4 — added "Component Suggestions" link to the
#   Components dropdown, alongside "Component Types" and "Run Statuses".
#   Lesson for future sessions: when shipping a new admin:: resources block,
#   always check decor/app/views/layouts/admin.html.erb in the same session —
#   the routes.rb entry alone does not surface the feature to users.
#
# Session 64: Component Suggestions Phase 2 — JSON endpoint + Stimulus typeahead. All files implemented.
#   8 files delivered:
#   routes.rb v3.4 — added owner-facing GET /component_suggestions route.
#   component_suggestions_controller.rb v1.0 NEW — JSON endpoint (require_login,
#     not under admin namespace). Returns up to 10 prefix matches via
#     ComponentSuggestion.matching, shaped as { order_number, description, category }.
#   component_suggestion_controller.js v1.0 NEW — Stimulus typeahead controller.
#     Targets: orderNumberInput, descriptionInput, serialNumberInput, verifiedFlag, dropdown.
#     Debounced (250ms) fetch on input; keyboard nav (ArrowUp/Down/Enter/Escape);
#     auto-accepts when results narrow to exactly one match; Tailwind dropdown
#     styled to match Tom Select's option appearance.
#   components/_form.html.erb v1.9 — wired component-suggestion controller onto
#     form_with; added orderNumberInput/serialNumberInput/descriptionInput targets
#     and the hidden order_number_verified field (verifiedFlag target).
#   components_controller.rb v2.0 — added :order_number_verified to strong params.
#   component_suggestions_controller_test.rb v1.0 NEW — covers require_login,
#     blank query, prefix matching, substring-non-match, null field passthrough,
#     and the 10-result limit.
#   DECOR_PROJECT.md v2.54 (this update).
#
#   Design notes for next session:
#   - Auto-accept on single match is implemented client-side only (Stimulus);
#     no server-side change needed since the endpoint already returns ≤10 matches.
#   - order_number_verified is reset to false client-side whenever the user
#     clears the order_number field or types a query with zero matches. It is
#     NOT reset merely because the user edits the field while suggestions are
#     still loading — only on confirmed zero-match or empty-field states.
#   - importmap.rb required NO change: pin_all_from "app/javascript/controllers"
#     auto-discovers the new Stimulus controller file.
#
# Session 62: Planning only — Component Suggestions feature (2-phase plan).
#   No files implemented. DECOR_PROJECT.md updated with:
#   - ComponentSuggestion in Data Model Overview
#   - order_number_verified added to Component model entry
#   - Component Suggestions Feature section (Phase 1 + Phase 2 plan)
#
# Session 61: Computers Statistics page + Statistics nav dropdown.
#   7 files: routes.rb v3.2, computer_statistics_controller.rb v1.1 NEW,
#   computer_statistics_helper.rb v1.0 NEW, computer_statistics/_filters.html.erb v1.0 NEW,
#   computer_statistics/index.html.erb v1.1 NEW, _navigation.html.erb v2.4,
#   computer_statistics_controller_test.rb v1.1 NEW.
#
# Session 59: System tests Track 1 + DRY fix.
#   8 files: application_system_test_case v1.1, authentication_helper v2.1,
#   computers_controller_test v1.11, authentication_test v1.0 NEW,
#   computers_filters_test v1.0 NEW, components_filters_test v1.0 NEW,
#   software_items_filters_test v1.0 NEW, connection_groups_test (system) v1.0 NEW.
#
# Session 58: Newsletter tests + component_conditions UI rename fixes.
#   12 files: newsletters.yml v1.0 NEW, owners.yml v2.2, owner_test v1.5,
#   newsletter_test v1.1 NEW, newsletters_controller_test v1.0 NEW,
#   owners_controller_test (admin) v1.3, newsletter_mailer_test v1.0 NEW,
#   owners_controller_test v2.0, newsletters_controller v1.1,
#   component_conditions/_form v1.2, RAILS_SPECIFICS v3.2.
#
# Session 54: Tom Select searchable combobox.
#   7 files: tom_select_controller.js v1.0 NEW, importmap.rb v1.1,
#   application.html.erb v1.4, computers/_form.html.erb v2.6,
#   components/_form.html.erb v1.8, software_items/_form.html.erb v1.1,
#   COMMON_BEHAVIOR.md v2.6.

**DEC Owner's Registry Project - Specific Information**

**Last Updated:** July 20, 2026 (Session 74 — documentation compression
  pass; no project code changed this session; v2.65)
**Current Status:** Sessions 1–72 all committed, pushed, merged, and deployed
  to main (see prior entries below for full detail). Session 73's Category
  Help Pages feature (7 files) is still **code-complete but NOT YET tested,
  lint/security-scanned, or committed** — see "Category Help Pages Feature —
  Session 73" below and SESSION_HANDOVER.md "Session 73 Summary" for the
  full NOT YET DONE checklist. Session 74 touched only this file,
  SESSION_HANDOVER.md, and RAILS_SPECIFICS.md (compression pass) — no
  application code changed, so this checklist is unaffected.

---

## Directory Tree

**Command to regenerate** (run from parent of decor/, pipe to decor_tree.txt and upload):
```bash
tree decor/ -I "node_modules|.git|tmp|storage|log|.DS_Store|*.lock|assets|cache|pids|sockets" --dirsfirst -F --prune -L 6 > decor_tree.txt
```

**Current tree** (as of Session 41 — Sessions 43–59 add new files; upload decor_tree.txt to refresh):
```
decor//
├── app/
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── base_controller.rb
│   │   │   ├── bulk_uploads_controller.rb
│   │   │   ├── component_conditions_controller.rb
│   │   │   ├── component_types_controller.rb
│   │   │   ├── computer_models_controller.rb           ← Session 41 (v1.4)
│   │   │   ├── conditions_controller.rb
│   │   │   ├── connection_types_controller.rb
│   │   │   ├── component_suggestions_controller.rb     ← Session 63 (v1.0) NEW
│   │   │   ├── component_order_numbers_controller.rb   ← Session 65 (v1.0) NEW
│   │   │   ├── data_transfers_controller.rb            ← Session 63 (v1.4)
│   │   │   ├── invites_controller.rb
│   │   │   ├── newsletters_controller.rb               ← Session 58 (v1.1)
│   │   │   ├── owners_controller.rb
│   │   │   ├── run_statuses_controller.rb
│   │   │   ├── site_texts_controller.rb                ← Session 53 (v1.2)
│   │   │   ├── software_conditions_controller.rb       ← Session 44 (v1.0) NEW
│   │   │   └── software_names_controller.rb            ← Session 44 (v1.0) NEW
│   │   ├── concerns/
│   │   │   ├── authentication.rb
│   │   │   └── pagination.rb
│   │   ├── application_controller.rb
│   │   ├── component_suggestions_controller.rb         ← Session 64 (v1.0) NEW
│   │   ├── components_controller.rb                    ← Session 70 (v2.1)
│   │   ├── computers_controller.rb                     ← Session 70 (v1.23)
│   │   ├── connection_groups_controller.rb
│   │   ├── data_transfers_controller.rb                ← Session 49 (v1.6)
│   │   ├── home_controller.rb                         ← Session 51 (v1.1)
│   │   ├── owners_controller.rb                        ← Session 45 (v2.0)
│   │   ├── password_resets_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── site_texts_controller.rb
│   │   └── software_items_controller.rb                ← Session 50 (v1.3)
│   ├── helpers/
│   │   ├── computers_helper.rb                        ← Session 52 (v1.8)
│   │   ├── components_helper.rb                       ← Session 52 (v1.4)
│   │   └── software_items_helper.rb                   ← Session 50 (v1.0) NEW
│   ├── models/
│   │   ├── component_suggestion.rb                    ← Session 67 (v1.1)
│   │   ├── computer.rb                                 ← Session 70 (v2.2)
│   │   ├── computer_model.rb                          ← Session 41 (v1.3)
│   │   ├── component.rb                                ← Session 70 (v1.6)
│   │   ├── newsletter.rb
│   │   ├── owner.rb                                   ← Session 43 (v1.5)
│   │   ├── software_condition.rb                      ← Session 43 (v1.0) NEW
│   │   ├── software_item.rb                           ← Session 43 (v1.0) NEW
│   │   └── software_name.rb                           ← Session 43 (v1.0) NEW
│   ├── services/
│   │   ├── all_owners_export_service.rb               ← Session 50 (v1.1)
│   │   ├── component_suggestion_export_service.rb     ← Session 63 (v1.0) NEW
│   │   ├── component_suggestion_import_service.rb     ← Session 67 (v2.0)
│   │   ├── manual_component_suggestions_export_service.rb ← Session 67 (v1.1) NEW
│   │   ├── component_order_number_revalidation_service.rb ← Session 65 (v1.0) NEW
│   │   ├── unvalidated_order_numbers_export_service.rb ← Session 65 (v1.0) NEW
│   │   ├── owner_export_service.rb                     ← Session 70 (v1.11)
│   │   └── owner_import_service.rb                     ← Session 70 (v1.12)
│   └── views/
│       ├── admin/
│       │   ├── component_conditions/
│       │   │   └── _form.html.erb                     ← Session 58 (v1.2)
│       │   ├── component_suggestions/                  ← Session 63 NEW
│       │   │   ├── _form.html.erb                     ← Session 69 (v1.1)
│       │   │   ├── _filters.html.erb                  ← Session 69 (v1.1)
│       │   │   ├── _component_suggestion.html.erb     ← Session 67 (v1.0) NEW
│       │   │   ├── edit.html.erb                      ← Session 63 (v1.0) NEW
│       │   │   ├── index.html.erb                     ← Session 69 (v1.4)
│       │   │   ├── index.turbo_stream.erb              ← Session 67 (v1.0) NEW
│       │   │   └── new.html.erb                       ← Session 63 (v1.0) NEW
│       │   ├── data_transfers/
│       │   │   └── show.html.erb                      ← Session 63 (v1.4)
│       │   ├── newsletters/
│       │   │   └── (views)
│       │   ├── owners/
│       │   │   └── index.html.erb                     ← Session 53 (v1.2)
│       │   ├── site_texts/
│       │   │   ├── delete_confirm.html.erb            ← Session 53 (v1.1)
│       │   │   ├── download_confirm.html.erb          ← Session 53 (v1.0) NEW
│       │   │   └── new.html.erb
│       │   ├── software_conditions/
│       │   └── software_names/
│       ├── common/
│       │   └── _navigation.html.erb                   ← Session 61 (v2.4)
│       ├── data_transfers/
│       │   └── show.html.erb                          ← Session 49 (v1.9)
│       ├── home/
│       │   └── index.html.erb                         ← Session 51 (v4.4)
│       ├── layouts/
│       │   └── admin.html.erb                         ← Session 69 (v2.8)
│       ├── computers/
│       │   ├── _form.html.erb                         ← Session 71 (display fix)
│       │   └── show.html.erb                          ← Session 47 (v2.2)
│       ├── owners/
│       │   ├── _owner.html.erb                        ← Session 41 (v3.5)
│       │   ├── computers.html.erb                     ← Session 71 (display fix)
│       │   ├── components.html.erb                    ← Session 71 (display fix)
│       │   ├── connections.html.erb                   ← Session 45 (v1.2)
│       │   ├── peripherals.html.erb                   ← Session 71 (display fix)
│       │   ├── show.html.erb                          ← Session 46 (v2.4)
│       │   └── software.html.erb                      ← Session 46 (v1.1)
│       └── software_items/
│           ├── _filters.html.erb                      ← Session 50 (v1.0) NEW
│           ├── _form.html.erb                         ← Session 46 (v1.0) NEW
│           ├── _software_item.html.erb                ← Session 48 (v1.0) NEW
│           ├── edit.html.erb                          ← Session 46 (v1.0) NEW
│           ├── index.html.erb                         ← Session 50 (v1.1)
│           ├── index.turbo_stream.erb                 ← Session 48 (v1.0) NEW
│           ├── new.html.erb                           ← Session 46 (v1.0) NEW
│           └── show.html.erb                          ← Session 46 (v1.1)
├── config/
│   └── routes.rb                                      ← Session 67 (v3.6)
├── db/
│   └── migrate/
│       ├── 20260401000000_create_software_names.rb    ← Session 43 (v1.0) NEW
│       ├── 20260401000100_create_software_conditions.rb ← Session 43 (v1.0) NEW
│       ├── 20260401000200_create_software_items.rb    ← Session 43 (v1.0) NEW
│       ├── 20260511000100_create_component_suggestions.rb ← Session 63 (v1.0) NEW
│       ├── 20260511000200_add_order_number_verified_to_components.rb ← Session 63 (v1.0) NEW
│       ├── 20260707000100_add_manual_and_enlarge_description_to_component_suggestions.rb ← Session 67 (v1.0) NEW
│       ├── 20260716000100_add_owner_part_number_to_computers_and_components.rb ← Session 70 (v1.0) NEW
│       └── 20260716000200_enforce_owner_part_number_constraints.rb ← Session 70 (v1.0) NEW
└── test/
    ├── controllers/
    │   ├── admin/
    │   │   ├── component_suggestions_controller_test.rb ← Session 67 (v1.1)
    │   │   ├── component_order_numbers_controller_test.rb ← Session 65 (v1.0) NEW
    │   │   ├── computer_models_controller_test.rb      ← Session 41 (v1.3)
    │   │   ├── data_transfers_controller_test.rb       ← Session 50 (v1.3)
    │   │   ├── newsletters_controller_test.rb          ← Session 58 (v1.0) NEW
    │   │   ├── owners_controller_test.rb               ← Session 58 (v1.3)
    │   │   ├── site_texts_controller_test.rb           ← Session 53 (v1.1)
    │   │   ├── software_conditions_controller_test.rb  ← Session 44 (v1.0) NEW
    │   │   └── software_names_controller_test.rb       ← Session 44 (v1.0) NEW
    │   ├── computers_controller_test.rb                ← Session 70 (updated)
    │   ├── components_controller_test.rb               ← Session 70 (updated)
    │   ├── connection_groups_controller_test.rb        ← Session 38 (v1.1)
    │   ├── data_transfers_controller_test.rb           ← Session 50 (v1.4)
    │   ├── owners_controller_test.rb                  ← Session 58 (v2.0)
    │   └── software_items_controller_test.rb          ← Session 50 (v1.5)
    ├── fixtures/
    │   ├── computer_models.yml                         ← Session 41 (v1.3)
    │   ├── computers.yml                              ← Session 70 (v1.10)
    │   ├── components.yml                              ← Session 70 (v1.5)
    │   ├── newsletters.yml                            ← Session 58 (v1.0) NEW
    │   ├── owners.yml                                 ← Session 58 (v2.2)
    │   ├── software_conditions.yml                    ← Session 43 (v1.0) NEW
    │   ├── software_items.yml                         ← Session 43 (v1.0) NEW
    │   ├── component_suggestions.yml                  ← Session 63 (v1.0) NEW
    │   └── software_names.yml                         ← Session 43 (v1.0) NEW
    ├── mailers/
    │   └── newsletter_mailer_test.rb                  ← Session 58 (v1.0) NEW
    ├── models/
    │   ├── computer_model_test.rb                     ← Session 41 (v1.3)
    │   ├── computer_test.rb                           ← Session 70 (updated)
    │   ├── component_test.rb                          ← Session 70 (updated)
    │   ├── newsletter_test.rb                         ← Session 58 (v1.1) NEW
    │   ├── owner_test.rb                              ← Session 58 (v1.5)
    │   ├── software_condition_test.rb                 ← Session 43 (v1.0) NEW
    │   ├── software_item_test.rb                      ← Session 43 (v1.0) NEW
    │   ├── component_suggestion_test.rb                ← Session 67 (v1.1)
    │   └── software_name_test.rb                      ← Session 43 (v1.0) NEW
    ├── services/
    │   ├── component_suggestion_export_service_test.rb ← Session 63 (v1.0) NEW
    │   ├── component_suggestion_import_service_test.rb ← Session 67 (v2.0)
    │   ├── manual_component_suggestions_export_service_test.rb ← Session 67 (v1.0) NEW
    │   ├── component_order_number_revalidation_service_test.rb ← Session 65 (v1.0) NEW
    │   ├── unvalidated_order_numbers_export_service_test.rb ← Session 65 (v1.0) NEW
    │   ├── computer_model_export_service_test.rb      ← Session 41 (v1.2)
    │   ├── computer_model_import_service_test.rb      ← Session 41 (v1.2)
    │   ├── owner_export_service_test.rb               ← Session 70 (updated)
    │   └── owner_import_service_test.rb               ← Session 70 (updated)
    ├── support/
    │   ├── authentication_helper.rb                   ← Session 59 (v2.1)
    │   └── response_helpers.rb                        ← Session 50 (v1.0) NEW
    ├── system/
    │   ├── authentication_test.rb                     ← Session 59 (v1.0) NEW
    │   ├── components_filters_test.rb                 ← Session 59 (v1.0) NEW
    │   ├── computers_filters_test.rb                  ← Session 59 (v1.0) NEW
    │   ├── connection_groups_test.rb                  ← Session 59 (v1.0) NEW
    │   └── software_items_filters_test.rb             ← Session 59 (v1.0) NEW
    ├── application_system_test_case.rb                ← Session 59 (v1.1)
    └── test_helper.rb                                 ← Session 50 (v1.2)
```

**Note (Session 72):** the tree above is annotated with the versions/sessions
known from delivered file headers and the Key file versions table, but has
not been regenerated from an actual `tree` command output since Session 41.
Run the command above and upload a fresh `decor_tree.txt` when convenient —
this is a documentation nicety, not a blocker (Gemfile/Gemfile.lock, which
Session 72 touched, aren't shown in this filtered tree at all since `*.lock`
is excluded).

---

**Key file versions** (updated each session):

    decor/docs/claude/DECOR_PROJECT.md                                                  v2.65 ← Session 74
    decor/docs/claude/SESSION_HANDOVER.md                                               v74.0 ← Session 74
    decor/docs/claude/RAILS_SPECIFICS.md                                                v3.8  ← Session 74
    decor/docs/claude/DECOR_PROJECT.md                                                  v2.64 ← Session 73
    decor/docs/claude/SESSION_HANDOVER.md                                               v73.0 ← Session 73
    decor/docs/claude/RAILS_SPECIFICS.md                                                v3.7  ← Session 73
    decor/app/models/site_text.rb                                                       v1.2  ← Session 73
    decor/app/controllers/site_texts_controller.rb                                       v1.1  ← Session 73
    decor/app/controllers/admin/site_texts_controller.rb                                 v1.3  ← Session 73
    decor/config/routes.rb                                                               v3.7  ← Session 73
    decor/app/views/common/_navigation.html.erb                                          v2.5  ← Session 73
    decor/test/controllers/admin/site_texts_controller_test.rb                           v1.2  ← Session 73
    decor/test/controllers/site_texts_controller_test.rb                                 v1.0  ← Session 73 NEW
    decor/docs/claude/DECOR_PROJECT.md                                                  v2.63 ← Session 72
    decor/docs/claude/SESSION_HANDOVER.md                                               v72.0 ← Session 72
    decor/Gemfile.lock (loofah, rails-html-sanitizer, sqlite3, websocket-driver bumped) ← Session 72
    decor/docs/claude/DECOR_PROJECT.md                                                  v2.61 ← Session 70
    decor/docs/claude/SESSION_HANDOVER.md                                               v71.0 ← Session 70
    decor/db/migrate/20260716000100_add_owner_part_number_to_computers_and_components.rb v1.0 ← Session 70 NEW
    decor/db/migrate/20260716000200_enforce_owner_part_number_constraints.rb            v1.0  ← Session 70 NEW
    decor/app/models/computer.rb                                                        v2.2  ← Session 70
    decor/app/models/component.rb                                                       v1.6  ← Session 70
    decor/app/controllers/computers_controller.rb                                       v1.23 ← Session 70
    decor/app/controllers/components_controller.rb                                      v2.1  ← Session 70
    decor/app/views/computers/_form.html.erb                                            v2.7  ← Session 70
    decor/app/views/components/_form.html.erb                                           v1.12 ← Session 70
    decor/app/services/owner_export_service.rb                                          v1.11 ← Session 70
    decor/app/services/owner_import_service.rb                                          v1.12 ← Session 70
    decor/test/fixtures/computers.yml                                                   v1.10 ← Session 70
    decor/test/fixtures/components.yml                                                  v1.5  ← Session 70
    decor/docs/claude/COMMON_BEHAVIOR.md                                                v2.9  ← Session 69
    decor/docs/claude/DECOR_PROJECT.md                                                  v2.60 ← Session 69
    decor/docs/claude/SESSION_HANDOVER.md                                               v70.0 ← Session 69
    decor/app/views/computers/_filters.html.erb                                         v1.7  ← Session 69
    decor/app/views/computers/index.html.erb                                            v1.10 ← Session 69
    decor/app/views/computers/_computer_component_form.html.erb                         v1.4  ← Session 69
    decor/app/views/computers/_computer.html.erb                                        v1.11 ← Session 69
    decor/app/views/components/_form.html.erb                                           v1.11 ← Session 69
    decor/app/views/components/show.html.erb                                            v1.8  ← Session 69
    decor/app/views/components/index.html.erb                                           v1.7  ← Session 69
    decor/app/views/computer_statistics/index.html.erb                                  v1.2  ← Session 69
    decor/app/views/owners/computers.html.erb                                           v1.5  ← Session 69
    decor/app/views/owners/peripherals.html.erb                                         v1.4  ← Session 69
    decor/app/views/owners/components.html.erb                                          v1.5  ← Session 69
    decor/app/views/admin/component_suggestions/_form.html.erb                          v1.1  ← Session 69
    decor/app/views/admin/component_suggestions/_filters.html.erb                       v1.1  ← Session 69
    decor/app/views/admin/component_suggestions/index.html.erb                          v1.4  ← Session 69
    decor/app/views/layouts/admin.html.erb                                              v2.8  ← Session 69
    decor/docs/claude/RAILS_SPECIFICS.md                                                v3.6  ← Session 67
    decor/docs/claude/COMMON_BEHAVIOR.md                                                v2.8  ← Session 67
    decor/docs/claude/DECOR_PROJECT.md                                                  v2.59 ← Session 67
    decor/db/migrate/20260707000100_add_manual_and_enlarge_description_to_component_suggestions.rb  v1.0 ← Session 67 NEW
    decor/app/models/component_suggestion.rb                                            v1.1  ← Session 67
    decor/app/services/component_suggestion_import_service.rb                           v2.0  ← Session 67
    decor/app/services/manual_component_suggestions_export_service.rb                   v1.1  ← Session 67 NEW
    decor/app/controllers/admin/component_suggestions_controller.rb                     v1.2  ← Session 67
    decor/config/routes.rb                                                              v3.6  ← Session 67
    decor/app/views/layouts/admin.html.erb                                              v2.7  ← Session 67
    decor/app/helpers/admin/component_suggestions_helper.rb                             v1.0  ← Session 67 NEW
    decor/app/views/admin/component_suggestions/_filters.html.erb                       v1.0  ← Session 67 NEW
    decor/app/views/admin/component_suggestions/_component_suggestion.html.erb          v1.0  ← Session 67 NEW
    decor/app/views/admin/component_suggestions/index.html.erb                          v1.1  ← Session 67
    decor/app/views/admin/component_suggestions/index.turbo_stream.erb                  v1.0  ← Session 67 NEW
    decor/test/models/component_suggestion_test.rb                                      v1.1  ← Session 67
    decor/test/services/manual_component_suggestions_export_service_test.rb             v1.0  ← Session 67 NEW
    decor/test/services/component_suggestion_import_service_test.rb                     v2.0  ← Session 67
    decor/test/controllers/admin/component_suggestions_controller_test.rb               v1.1  ← Session 67
    decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md                                    v1.0  ← Session 66 NEW
    decor/docs/claude/SESSION_HANDOVER.md                                               v68.0 ← Session 66
    decor/docs/claude/DECOR_PROJECT.md                                                  v2.58 ← Session 66
    decor/config/routes.rb                                                              v3.5  ← Session 65
    decor/app/controllers/admin/component_order_numbers_controller.rb                   v1.0  ← Session 65 NEW
    decor/app/services/component_order_number_revalidation_service.rb                   v1.0  ← Session 65 NEW
    decor/app/services/unvalidated_order_numbers_export_service.rb                      v1.0  ← Session 65 NEW
    decor/app/views/layouts/admin.html.erb                                              v2.6  ← Session 65
    decor/test/services/component_order_number_revalidation_service_test.rb             v1.0  ← Session 65 NEW
    decor/test/services/unvalidated_order_numbers_export_service_test.rb                v1.0  ← Session 65 NEW
    decor/test/controllers/admin/component_order_numbers_controller_test.rb             v1.0  ← Session 65 NEW
    decor/docs/claude/RAILS_SPECIFICS.md                                                v3.5  ← Session 65
    decor/docs/claude/DECOR_PROJECT.md                                                  v2.53 ← Session 63
    decor/db/migrate/20260511000100_create_component_suggestions.rb                     v1.0  ← Session 63 NEW
    decor/db/migrate/20260511000200_add_order_number_verified_to_components.rb          v1.0  ← Session 63 NEW
    decor/app/models/component_suggestion.rb                                            v1.0  ← Session 63 NEW
    decor/test/fixtures/component_suggestions.yml                                       v1.0  ← Session 63 NEW
    decor/app/controllers/admin/component_suggestions_controller.rb                     v1.0  ← Session 63 NEW
    decor/app/views/admin/component_suggestions/index.html.erb                          v1.0  ← Session 63 NEW
    decor/app/views/admin/component_suggestions/_form.html.erb                          v1.0  ← Session 63 NEW
    decor/app/views/admin/component_suggestions/new.html.erb                            v1.0  ← Session 63 NEW
    decor/app/views/admin/component_suggestions/edit.html.erb                           v1.0  ← Session 63 NEW
    decor/config/routes.rb                                                              v3.3  ← Session 63
    decor/app/controllers/admin/data_transfers_controller.rb                            v1.4  ← Session 63
    decor/app/views/admin/data_transfers/show.html.erb                                  v1.4  ← Session 63
    decor/app/services/component_suggestion_export_service.rb                           v1.0  ← Session 63 NEW
    decor/app/services/component_suggestion_import_service.rb                           v1.0  ← Session 63 NEW
    decor/test/models/component_suggestion_test.rb                                      v1.0  ← Session 63 NEW
    decor/test/services/component_suggestion_export_service_test.rb                     v1.0  ← Session 63 NEW
    decor/test/services/component_suggestion_import_service_test.rb                     v1.0  ← Session 63 NEW
    decor/test/controllers/admin/component_suggestions_controller_test.rb               v1.0  ← Session 63 NEW
    decor/docs/claude/SESSION_HANDOVER.md                                               v65.0 ← Session 60
    decor/config/routes.rb                                                              v3.2  ← Session 61
    decor/app/controllers/computer_statistics_controller.rb                             v1.1  ← Session 61 NEW
    decor/app/helpers/computer_statistics_helper.rb                                     v1.0  ← Session 61 NEW
    decor/app/views/computer_statistics/_filters.html.erb                               v1.0  ← Session 61 NEW
    decor/app/views/computer_statistics/index.html.erb                                  v1.1  ← Session 61 NEW
    decor/app/views/common/_navigation.html.erb                                        v2.4  ← Session 61
    decor/test/controllers/computer_statistics_controller_test.rb                       v1.0  ← Session 61 NEW
    decor/docs/claude/RAILS_SPECIFICS.md                                                v3.3  ← Session 60
    decor/test/application_system_test_case.rb                                          v1.1  ← Session 59
    decor/test/support/authentication_helper.rb                                         v2.1  ← Session 59
    decor/test/controllers/computers_controller_test.rb                                 v1.11 ← Session 59
    decor/test/system/authentication_test.rb                                            v1.0  ← Session 59 NEW
    decor/test/system/computers_filters_test.rb                                         v1.0  ← Session 59 NEW
    decor/test/system/components_filters_test.rb                                        v1.0  ← Session 59 NEW
    decor/test/system/software_items_filters_test.rb                                    v1.0  ← Session 59 NEW
    decor/test/system/connection_groups_test.rb                                         v1.0  ← Session 59 NEW
    decor/docs/claude/COMMON_BEHAVIOR.md                                                v2.6  ← Session 54
    decor/app/javascript/controllers/tom_select_controller.js                           v1.0  ← Session 54 NEW
    decor/config/importmap.rb                                                           v1.1  ← Session 54
    decor/app/views/layouts/application.html.erb                                        v1.4  ← Session 54
    decor/app/views/computers/_form.html.erb                                            v2.6  ← Session 54
    decor/app/views/components/_form.html.erb                                           v1.8  ← Session 54
    decor/app/views/software_items/_form.html.erb                                       v1.1  ← Session 54
    decor/docs/claude/RAILS_SPECIFICS.md                                                v3.2  ← Session 58
    decor/test/fixtures/newsletters.yml                                                 v1.0  ← Session 58 NEW
    decor/test/fixtures/owners.yml                                                      v2.2  ← Session 58
    decor/test/models/owner_test.rb                                                     v1.5  ← Session 58
    decor/test/models/newsletter_test.rb                                                v1.1  ← Session 58 NEW
    decor/test/controllers/admin/newsletters_controller_test.rb                         v1.0  ← Session 58 NEW
    decor/test/controllers/admin/owners_controller_test.rb                              v1.3  ← Session 58
    decor/test/mailers/newsletter_mailer_test.rb                                        v1.0  ← Session 58 NEW
    decor/test/controllers/owners_controller_test.rb                                    v2.0  ← Session 58
    decor/app/controllers/admin/newsletters_controller.rb                               v1.1  ← Session 58
    decor/app/views/admin/component_conditions/_form.html.erb                          v1.2  ← Session 58
    decor/app/views/admin/owners/index.html.erb                                         v1.2  ← Session 53
    decor/config/routes.rb                                                              v3.2  ← Session 61
    decor/app/controllers/admin/site_texts_controller.rb                                v1.2  ← Session 53
    decor/app/views/admin/site_texts/download_confirm.html.erb                         v1.0  ← Session 53 NEW
    decor/app/views/admin/site_texts/delete_confirm.html.erb                           v1.1  ← Session 53
    decor/app/views/layouts/admin.html.erb                                             v2.2  ← Session 53
    decor/app/views/common/_navigation.html.erb                                        v2.4  ← Session 61
    decor/test/controllers/admin/site_texts_controller_test.rb                         v1.1  ← Session 53
    decor/app/controllers/computers_controller.rb                                       v1.22 ← Session 52
    decor/app/views/components/_form.html.erb                                           v1.7  ← Session 52
    decor/app/controllers/components_controller.rb                                      v1.9  ← Session 52
    decor/app/views/computers/_filters.html.erb                                         v1.6  ← Session 52
    decor/app/helpers/computers_helper.rb                                               v1.8  ← Session 52
    decor/app/helpers/components_helper.rb                                              v1.4  ← Session 52
    decor/app/views/components/_filters.html.erb                                        v1.2  ← Session 52
    decor/app/views/components/index.html.erb                                           v1.6  ← Session 52
    decor/app/controllers/home_controller.rb                                            v1.1  ← Session 51
    decor/app/views/home/index.html.erb                                                 v4.4  ← Session 51
    decor/app/helpers/software_items_helper.rb                                          v1.0  ← Session 50 NEW
    decor/app/controllers/software_items_controller.rb                                  v1.3  ← Session 50
    decor/app/views/software_items/_filters.html.erb                                    v1.0  ← Session 50 NEW
    decor/app/views/software_items/index.html.erb                                       v1.1  ← Session 50
    decor/test/controllers/software_items_controller_test.rb                            v1.5  ← Session 50
    decor/test/test_helper.rb                                                           v1.2  ← Session 50
    decor/test/support/response_helpers.rb                                              v1.0  ← Session 50 NEW
    decor/app/services/all_owners_export_service.rb                                     v1.1  ← Session 50
    decor/test/controllers/data_transfers_controller_test.rb                            v1.4  ← Session 50
    decor/test/controllers/admin/data_transfers_controller_test.rb                      v1.3  ← Session 50
    decor/app/controllers/data_transfers_controller.rb                                  v1.6  ← Session 49
    decor/app/views/data_transfers/show.html.erb                                        v1.9  ← Session 49
    decor/app/services/owner_export_service.rb                                          v1.10 ← Session 49
    decor/app/services/owner_import_service.rb                                          v1.11 ← Session 49
    decor/test/services/owner_export_service_test.rb                                    v2.0  ← Session 49
    decor/test/services/owner_import_service_test.rb                                    v1.7  ← Session 49
    decor/app/controllers/admin/data_transfers_controller.rb                            v1.3  ← Session 48
    decor/app/views/admin/data_transfers/show.html.erb                                  v1.3  ← Session 48
    decor/app/views/software_items/_software_item.html.erb                              v1.0  ← Session 48 NEW
    decor/app/views/software_items/index.turbo_stream.erb                               v1.0  ← Session 48 NEW
    decor/app/views/software_items/new.html.erb                                         v1.0  ← Session 46 NEW
    decor/app/views/software_items/edit.html.erb                                        v1.0  ← Session 46 NEW
    decor/app/views/software_items/_form.html.erb                                       v1.0  ← Session 46 NEW
    decor/app/views/owners/software.html.erb                                            v1.1  ← Session 46
    decor/app/views/software_items/show.html.erb                                        v1.1  ← Session 46
    decor/app/views/owners/show.html.erb                                                v2.4  ← Session 46
    decor/app/controllers/owners_controller.rb                                          v2.0  ← Session 45
    decor/app/views/owners/computers.html.erb                                           v1.4  ← Session 45
    decor/app/views/owners/peripherals.html.erb                                         v1.3  ← Session 45
    decor/app/views/owners/components.html.erb                                          v1.4  ← Session 45
    decor/app/views/owners/connections.html.erb                                         v1.2  ← Session 45
    decor/test/controllers/owners_controller_test.rb                                    v1.9  ← Session 45
    decor/app/controllers/admin/software_names_controller.rb                            v1.0  ← Session 44 NEW
    decor/app/controllers/admin/software_conditions_controller.rb                       v1.0  ← Session 44 NEW
    decor/test/controllers/admin/software_names_controller_test.rb                      v1.0  ← Session 44 NEW
    decor/test/controllers/admin/software_conditions_controller_test.rb                 v1.0  ← Session 44 NEW
    decor/db/migrate/20260401000000_create_software_names.rb                            v1.0  ← Session 43 NEW
    decor/db/migrate/20260401000100_create_software_conditions.rb                       v1.0  ← Session 43 NEW
    decor/db/migrate/20260401000200_create_software_items.rb                            v1.0  ← Session 43 NEW
    decor/app/models/software_name.rb                                                   v1.0  ← Session 43 NEW
    decor/app/models/software_condition.rb                                              v1.0  ← Session 43 NEW
    decor/app/models/software_item.rb                                                   v1.0  ← Session 43 NEW
    decor/app/models/owner.rb                                                           v1.5  ← Session 43
    decor/app/models/computer.rb                                                        v2.1  ← Session 43
    decor/test/fixtures/software_names.yml                                              v1.0  ← Session 43 NEW
    decor/test/fixtures/software_conditions.yml                                         v1.0  ← Session 43 NEW
    decor/test/fixtures/software_items.yml                                              v1.0  ← Session 43 NEW
    decor/test/models/software_name_test.rb                                             v1.0  ← Session 43 NEW
    decor/test/models/software_condition_test.rb                                        v1.0  ← Session 43 NEW
    decor/test/models/software_item_test.rb                                             v1.0  ← Session 43 NEW
    decor/app/helpers/computers_helper.rb                                               v1.6  ← Session 42
    decor/app/models/computer_model.rb                                                  v1.3  ← Session 41
    decor/app/controllers/admin/computer_models_controller.rb                           v1.4  ← Session 41
    decor/app/controllers/admin/data_transfers_controller.rb                            v1.2  ← Session 41
    decor/app/views/owners/_owner.html.erb                                              v3.5  ← Session 41
    decor/test/fixtures/computers.yml                                                   v1.9  ← Session 41
    decor/test/fixtures/computer_models.yml                                             v1.3  ← Session 41
    decor/test/models/computer_test.rb                                                  v1.7  ← Session 41
    decor/test/models/computer_model_test.rb                                            v1.3  ← Session 41
    decor/test/controllers/admin/computer_models_controller_test.rb                     v1.3  ← Session 41
    decor/test/services/computer_model_export_service_test.rb                           v1.2  ← Session 41
    decor/test/services/computer_model_import_service_test.rb                           v1.2  ← Session 41
    decor/test/models/connection_group_test.rb                                          v1.2  ← Session 39
    decor/test/models/connection_member_test.rb                                         v1.1  ← Session 39
    decor/test/controllers/connection_groups_controller_test.rb                         v1.1  ← Session 38
    decor/app/models/connection_group.rb                                                v1.2  ← Session 38
    decor/app/models/connection_member.rb                                               v1.1  ← Session 38
    decor/app/controllers/connection_groups_controller.rb                               v1.1  ← Session 38
    decor/app/views/connection_groups/_form.html.erb                                    v1.2  ← Session 38
    decor/app/javascript/controllers/connection_members_controller.js                   v1.1  ← Session 38
    decor/test/fixtures/connection_groups.yml                                           v1.1  ← Session 38
    decor/test/fixtures/connection_members.yml                                          v1.1  ← Session 38
    decor/app/services/computer_model_export_service.rb                                 v1.0  ← Session 24
    decor/app/services/computer_model_import_service.rb                                 v1.0  ← Session 24

---

## Data Model Overview

### Owner
- has_many :computers, dependent: :destroy
- has_many :components, dependent: :destroy
- has_many :software_items, dependent: :destroy        ← Session 43
- has_many :connection_groups, dependent: :destroy

### Computer
- belongs_to :owner
- belongs_to :computer_model
- belongs_to :computer_condition (optional)
- belongs_to :run_status (optional)
- has_many :components, dependent: :destroy
- has_many :software_items, dependent: :destroy        ← Session 43
- has_many :connection_members, dependent: :destroy
- has_many :connection_groups, through: :connection_members
- device_type enum: { computer: 0, peripheral: 2 }, prefix: true
  NOTE: value 1 (appliance) was removed in Session 41; DB migration run manually by user.
  Hash form required to preserve non-contiguous integers (0 and 2).
  Do NOT renumber peripheral to 1 — that would corrupt existing DB records.
- barter_status enum: 0=no_barter, 1=offered, 2=wanted (prefix: true)
- owner_part_number VARCHAR(20) NOT NULL  ← Session 70 (Owner Part Number feature)
  Defaults to "-" via before_validation when left blank (data-entry convenience).
  serial_number is ALSO now defaulted to "-" via before_validation when blank
  (was previously a hard validation error). Combined uniqueness scope widened
  from (owner_id, computer_model_id) to (owner_id, computer_model_id,
  owner_part_number, serial_number) — existing model dimension KEPT.

### ComputerModel
- device_type enum: { computer: 0, peripheral: 2 }, prefix: true
  Same hash form as Computer; appliance: 1 removed in Session 41.
- has_many :computers, dependent: :restrict_with_error
- validates :name, presence: true, uniqueness: true

### SoftwareName  ← Session 43
- has_many :software_items, dependent: :restrict_with_error
- validates :name, presence: true, uniqueness: true, length max 40
- validates :description, length max 100, optional
- Admin-managed (analogous to ComponentType)

### SoftwareCondition  ← Session 43
- has_many :software_items, dependent: :restrict_with_error
- validates :name, presence: true, uniqueness: true, length max 40
- validates :description, length max 100, optional
- Admin-managed. Initial values: Complete, Incomplete, Subset.
- NOTE: column is "name" (not "condition" like legacy component_conditions table)

### SoftwareItem  ← Session 43
- belongs_to :owner
- belongs_to :computer, optional: true
- belongs_to :software_name
- belongs_to :software_condition, optional: true
- barter_status enum: 0=no_barter, 1=offered, 2=wanted (prefix: true)
- version VARCHAR(20), optional
- description VARCHAR(100), optional
- history VARCHAR(200), optional

### Component
- order_number_verified: boolean NOT NULL, default false  ← Session 63 (Phase 1)
  true  = order_number was accepted from component_suggestions typeahead
  false = order_number typed freely (not validated against suggestions table)
- owner_part_number VARCHAR(20) NOT NULL  ← Session 70 (Owner Part Number feature)
  Defaults to "-" via before_validation when left blank, same as Computer.
  serial_number's previous allow_blank: true is REMOVED — serial_number is now
  presence: true and ALSO defaults to "-" via before_validation. This resolves
  the Computer/Component asymmetry flagged in the Session 69 design
  consultation. Combined uniqueness scope widened from (owner_id,
  component_type_id) to (owner_id, component_type_id, owner_part_number,
  serial_number) — existing type dimension KEPT.
  BEHAVIOUR CHANGE (Option B, confirmed Session 70): Session 28 intentionally
  allowed multiple unserialized spares of the same component_type per owner.
  A second such spare with no distinguishing value is now REJECTED at save
  time — no auto-assign mechanism exists going forward. Pre-existing
  collisions were one-time-backfilled with "SPARE-#{id}" placeholders by
  migration 20260716000100; this is a historical data fix, not an ongoing
  behaviour.

### ComponentSuggestion  ← Session 63 (Phase 1), updated Session 67 (Phase 4)
- Admin-managed lookup table for component order number autocomplete
- validates :order_number, presence: true, uniqueness: true, length max 20
- validates :description, length max 510, optional (widened from 100 — Session 67)
- validates :category, length max 40, optional (free text; informational display only)
- order_number VARCHAR(20) NOT NULL, UNIQUE index
- description  VARCHAR(510) nullable (widened Session 67 for concatenated main+variant text)
- category     VARCHAR(40)  nullable (NOT stored on component when suggestion accepted)
- manual       VARCHAR(1) nullable — enum :manual, { added: "a", modified: "m" }, prefix: true
  (Session 67). null = untouched bulk-import row (the normal case). "a" = added via
  the admin form, permanent. "m" = modified via the admin form after originating
  from bulk import. Read the RAW value with manual_before_type_cast, not
  read_attribute (see RAILS_SPECIFICS.md).
- scope :matching, ->(q) { where("order_number LIKE ?", "#{q}%").order(:order_number) }
- scope :order_number_contains, ->(q) { where("order_number LIKE ?", "%#{q}%") } (Session 67,
  substring match for the admin index filter — different from :matching's prefix match)

### SiteText  ← documented here for the first time in Session 73 (model itself
  ### dates to Session 18 — this was a genuine documentation gap, same shape
  ### as the still-open Session 68 gap noted in SESSION_HANDOVER.md's "!!
  ### GAP NOTICE !!"; closed now, not reconstructed from guesswork — read
  ### directly from decor/app/models/site_text.rb)
- Generic key/content lookup table backing every admin-managed, owner-facing
  static text page (README, News, Barter Trade, Privacy, and — as of Session
  73 — the 5 Category Help pages).
- key     VARCHAR(40) NOT NULL, UNIQUE index
- content TEXT NOT NULL (approved TEXT use — free-form Markdown body,
  per PROGRAMMING_GENERAL.md's TEXT exception for long free-form content)
- `KNOWN_TEXTS` (class constant) is the single source of truth: an array of
  `{ key:, title: }` hashes. Drives every admin selector (Upload/Download/
  Delete dropdowns) via `SiteText.options_for_select_list`, and page titles
  via `SiteText.title_for_key`. **Adding a new text page requires only a new
  KNOWN_TEXTS entry + a matching public route — no migration, no admin
  controller/view changes.**
- **Load-bearing naming convention (Session 73):** every public route's
  `as:` name MUST be identical to its `key` string. `Admin::
  SiteTextsController#url_for_key` (v1.3) relies on this to compute
  `send("#{key}_path")` generically for ANY key, with no per-key case
  branch. Breaking this convention for a future key silently falls back to
  `root_path` instead of the new page.
- `.for(key)` — convenience finder (Session 18)
- `SiteTextsController#show` (owner-facing, no `require_login` — public) and
  `Admin::SiteTextsController` (upload/download/delete, admin-only) are both
  fully generic over `KNOWN_TEXTS` — see "Category Help Pages Feature —
  Session 73" below for what was and wasn't touched.

### ConnectionGroup
- belongs_to :owner
- belongs_to :connection_type (optional)
- has_many :connection_members, dependent: :delete_all
- has_many :computers, through: :connection_members
- accepts_nested_attributes_for :connection_members, allow_destroy: true, reject_if: :all_blank
- owner_group_id: integer NOT NULL — auto-assigned (max+1) on create

### ConnectionMember
- belongs_to :connection_group
- belongs_to :computer
- owner_member_id: integer NOT NULL — per-group port numbering; auto-assigned on create
- label: VARCHAR(100) nullable

---

## Software Feature — Session Plan  ← Session 43

Option C (full separation) chosen. Software is NOT a variant of Components.

    Session A  Migrations, models, fixtures, model tests              DONE ✓ (Session 43)
    Session B  Admin CRUD: SoftwareNames + SoftwareConditions         DONE ✓ (Session 44)
    Session C  Owner-facing: Software index + show (read-only)        DONE ✓ (Session 45)
    Session D  Owner-facing: Software create + edit + destroy         DONE ✓ (Session 46)
    Session E  Computer/peripheral show page integration              DONE ✓ (Session 47)
    Session F  Export/Import service updates (deferrable)             DONE ✓ (Session 48)

---

## Component Suggestions Feature — Session Plan  ← Session 62

Typeahead autocomplete on `components.order_number` driven by an admin-managed
`component_suggestions` table. Helps users employ validated order numbers for
data consistency without blocking entry of new/unknown values.

### Confirmed design decisions

    component_suggestions table:
      order_number   VARCHAR(20)   NOT NULL, UNIQUE index
      description    VARCHAR(100)  nullable
      category       VARCHAR(40)  nullable — informational display only; NOT stored on component

    components table addition:
      order_number_verified   boolean   NOT NULL, default false

    Typeahead behaviour:
      - Typing in order_number fires GET /component_suggestions?query=…
      - Dropdown shows matching rows: order_number + description + category (display)
      - Narrowing to one match + ENTER (or ENTER on highlighted item):
          fills order_number AND description on the form
          sets hidden order_number_verified field to true
          moves focus to "Component Serial Number" (next field)
      - Zero matches: dropdown closes; user continues typing freely;
          order_number_verified stays false
      - User may overwrite description after accepting — order_number_verified
          remains true (records that order_number was validated, not description)
      - ESC closes dropdown without accepting

    Dropdown styling:
      Custom Stimulus-driven <ul> dropdown styled to match Tom Select visually
      (Tom Select cannot be applied to plain text inputs — it requires <select>)

### Phase 1 — data + admin CRUD + CSV import/export

    DONE ✓ (Session 63) — all 18 files implemented, all tests pass.

    Files delivered:
      decor/db/migrate/20260511000100_create_component_suggestions.rb
      decor/db/migrate/20260511000200_add_order_number_verified_to_components.rb
      decor/app/models/component_suggestion.rb
      decor/test/fixtures/component_suggestions.yml
      decor/app/controllers/admin/component_suggestions_controller.rb
      decor/app/views/admin/component_suggestions/{index,_form,new,edit}.html.erb
      decor/config/routes.rb (v3.3)
      decor/app/controllers/admin/data_transfers_controller.rb (v1.4)
      decor/app/views/admin/data_transfers/show.html.erb (v1.4)
      decor/app/services/component_suggestion_export_service.rb
      decor/app/services/component_suggestion_import_service.rb
      decor/test/models/component_suggestion_test.rb
      decor/test/services/component_suggestion_export_service_test.rb
      decor/test/services/component_suggestion_import_service_test.rb
      decor/test/controllers/admin/component_suggestions_controller_test.rb

### Phase 2 — JSON endpoint + Stimulus typeahead

    DONE ✓ (Session 64) — all 8 files implemented.

    Step  Deliverable
    1  ✓  Route: GET /component_suggestions?query=… (owner-facing, require_login)
    2  ✓  Controller: ComponentSuggestionsController#index
            Returns JSON array of { order_number, description, category }
            Limits to 10 results
            Query: ComponentSuggestion.matching(params[:query]).limit(10)
    3  ✓  Stimulus controller: component_suggestion_controller.js
            Targets: orderNumberInput, serialNumberInput, descriptionInput, dropdown
            On input → debounced fetch to JSON endpoint
            Renders dropdown <ul> (Tailwind-styled to match Tom Select visually)
            Keyboard: ArrowDown/ArrowUp navigate; ENTER accepts highlighted item
              (or auto-accepts when list narrows to exactly one)
            Accept: fills order_number + description, sets order_number_verified
              to true, closes dropdown, moves focus to serial_number input
            Free text: zero results → dropdown closes, order_number_verified false
            ESC: closes dropdown without accepting
    4  ✓  Update components/_form.html.erb
            Wire data-controller + data-targets to order_number, description,
              serial_number inputs
            Add hidden field order_number_verified
    5  ✓  Tests: ComponentSuggestionsController integration test (JSON endpoint)
    6  ✓  Update DECOR_PROJECT.md

    Files delivered:
      decor/config/routes.rb v3.4
      decor/app/controllers/component_suggestions_controller.rb v1.0 NEW
      decor/app/javascript/controllers/component_suggestion_controller.js v1.0 NEW
      decor/app/views/components/_form.html.erb v1.9
      decor/app/controllers/components_controller.rb v2.0
      decor/test/controllers/component_suggestions_controller_test.rb v1.0 NEW
      decor/docs/claude/DECOR_PROJECT.md v2.54

    Not yet verified (next session, if issues arise):
      - importmap.rb required no edit (pin_all_from auto-discovers controllers)
        but was not re-uploaded this session to confirm; flag if Stimulus fails
        to load the new controller in the browser.
      - component_suggestions.yml fixture file's exact keys were not available
        this session; the new controller test creates its own records instead
        of using fixtures, so this is not a blocker, but fixture-based tests
        elsewhere should still be checked if they reference ComponentSuggestion.

---

### Phase 3 — Order Number Bulk Maintenance (admin tools)  ← Session 65

    DONE ✓ (Session 65) — all 5 production files + 3 test files implemented.

    Two admin-only, non-resourceful actions added to the existing Components
    dropdown (per Ulli's original request — not a new dropdown):

      "Re-validate Order Numbers" (POST /admin/component_order_numbers/revalidate)
        Re-syncs order_number_verified for EVERY component against the current
        component_suggestions table. Rule: true iff order_number present AND
        matches a component_suggestions.order_number; else false. Applies
        immediately — no preview step (confirmed design decision). Idempotent.
        Uses update_column (skips model validations — this is a data-integrity
        sync, not a form edit). Redirects to admin_component_suggestions_path
        with a flash summarising verified/unverified/unchanged counts.

      "Download Unvalidated Order Numbers" (GET /admin/component_order_numbers/unvalidated)
        CSV, ONE ROW PER COMPONENT (confirmed — not deduplicated by order_number),
        ordered by component id (confirmed — not grouped by order_number).
        Only components with order_number_verified: false AND a non-blank
        order_number. Columns: order_number, component_type, owner,
        serial_number, description.

    Files delivered:
      decor/config/routes.rb (v3.5)
      decor/app/controllers/admin/component_order_numbers_controller.rb (v1.0 NEW)
      decor/app/services/component_order_number_revalidation_service.rb (v1.0 NEW)
      decor/app/services/unvalidated_order_numbers_export_service.rb (v1.0 NEW)
      decor/app/views/layouts/admin.html.erb (v2.6 — v2.5 shipped with a NameError,
        see RAILS_SPECIFICS.md v3.5 "Named Routes (as:) Inside namespace")
      decor/test/services/component_order_number_revalidation_service_test.rb (v1.0 NEW)
      decor/test/services/unvalidated_order_numbers_export_service_test.rb (v1.0 NEW)
      decor/test/controllers/admin/component_order_numbers_controller_test.rb (v1.0 NEW)

    Test design notes:
      All three test files create Component records fresh in-test, assigned to
      owners(:three) — the project's neutral owner — rather than adding new
      component fixtures. This was chosen over new components.yml fixtures
      because both new services scan ALL Component rows project-wide, so any
      hardcoded count assertion would be fragile against the existing fixture
      set (pdp11_memory, pdp11_cpu, spare_disk, pdp8_memory,
      spare_power_supply, charlie_vt100_terminal — all with blank order_number).
      All assertions are either on the specific records created in each test,
      or derived from Component.count at call time (never hardcoded).

    Status update (Session 66): confirmed by the user as committed, pushed,
      merged, and deployed — tests passed, pre-commit checklist complete.
      No longer "not yet done."

### Phase 4 — Order Number / Variant Simplification

    DONE ✓ (Session 67) — all four confirmed requirements implemented.
    (Session 66 was design-consultation only — the pivot away from the full
    variant-split design toward the simpler concatenated-field approach.
    See ORDER_NUMBER_VARIANT_DESIGN.md v1.0 for the shelved full design, kept
    for reference only.)

    1. Migration — DONE. decor/db/migrate/20260707000100_add_manual_and_
       enlarge_description_to_component_suggestions.rb: nullable manual
       VARCHAR(1) column ("a" = added, "m" = modified, null = untouched
       bulk-import row); description widened VARCHAR(100) → VARCHAR(510).
    2. "Download Manual Changes" admin feature — DONE. New
       ManualComponentSuggestionsExportService (CSV of manual: "a"/"m" rows,
       both together); new admin_component_suggestions download_manual
       collection route; new link in the Components dropdown
       (admin.html.erb v2.7).
    3. Import service rewrite — DONE. ComponentSuggestionImportService v2.0:
       unconditional delete_all + batched insert_all(unique_by: :order_number),
       replacing the O(n) per-row exists? check that caused production
       timeouts. See RAILS_SPECIFICS.md "insert_all Bypasses Model
       Validations..." for the accepted tradeoffs of this approach.
    4. Paginated + filterable admin index — DONE. Root cause of the slow
       load confirmed by code review (not diagnosis from scratch): v1.0 had
       NO pagination and NO filtering at all. Rewritten to follow the
       project's established geared_pagination "Load more" infinite-scroll
       pattern (matching software_items/computers/components), with a new
       filter sidebar (order_number substring search + manual flag filter).

    Files delivered (Session 67):
      decor/db/migrate/20260707000100_add_manual_and_enlarge_description_to_component_suggestions.rb  NEW
      decor/app/models/component_suggestion.rb                                    v1.0 → v1.1
      decor/app/services/component_suggestion_import_service.rb                   v1.0 → v2.0
      decor/app/services/manual_component_suggestions_export_service.rb          v1.0 → v1.1 NEW
      decor/app/controllers/admin/component_suggestions_controller.rb            v1.0 → v1.2
      decor/config/routes.rb                                                      v3.5 → v3.6
      decor/app/views/layouts/admin.html.erb                                      v2.6 → v2.7
      decor/app/helpers/admin/component_suggestions_helper.rb                     NEW
      decor/app/views/admin/component_suggestions/_filters.html.erb              NEW
      decor/app/views/admin/component_suggestions/_component_suggestion.html.erb NEW
      decor/app/views/admin/component_suggestions/index.html.erb                 v1.0 → v1.1
      decor/app/views/admin/component_suggestions/index.turbo_stream.erb         NEW

    Test files delivered/updated (Session 67):
      decor/test/models/component_suggestion_test.rb                            v1.0 → v1.1
      decor/test/services/manual_component_suggestions_export_service_test.rb   NEW
      decor/test/services/component_suggestion_import_service_test.rb           v1.0 → v2.0
      decor/test/controllers/admin/component_suggestions_controller_test.rb     v1.0 → v1.1
      decor/test/services/component_suggestion_export_service_test.rb          UNCHANGED — the
        underlying ComponentSuggestionExportService is untouched by Phase 4.

    Result: bin/rails test passing (900 tests, 0 failures, 0 errors) as of the
    last run this session. bundle-audit required one unrelated dependency bump
    (json gem, CVE-2026-54696, transitive — see RAILS_SPECIFICS.md "CI Security
    Checks") before coming back clean.

    Two mistakes made and corrected mid-session (both now codified as rules):
      - First guess at the download_manual path helper name was wrong
        (admin_download_manual_component_suggestions_path instead of the
        actual download_manual_admin_component_suggestions_path) — caught by
        running bin/rails routes before shipping. See RAILS_SPECIFICS.md
        "Collection Routes Nested in a Namespaced Resources Block."
      - index.turbo_stream.erb was initially written from general Rails/Turbo
        convention rather than an actual project file, explicitly flagged as
        such — this was still a Never-Guess violation regardless of the
        flag. Caught by the user, not self-corrected. See COMMON_BEHAVIOR.md
        "Flagging a Guess Does Not Satisfy Never-Guess." (The guess happened
        to match the real file once uploaded — luck, not compliance.)

    NOT YET DONE — required before this can be committed:
      All items completed as of Session 72 (lint, Brakeman, manual browser
      check, git workflow, json gem bump confirmed on main) — see
      SESSION_HANDOVER.md "Session 72 Summary" for the full incident.

**Data format adopted (Session 66 design pivot, superseded by the DONE
implementation above):** a full schema-split design (separate
`order_number_main`/`order_number_variant` columns, a three-state
`order_number_match_status` enum) was fully specified in consultation, then
shelved before implementation — risk of "self-indulgent featuritis" relative
to confirmed need at the ~55,000-record scale. Full shelved design kept for
reference only at `decor/docs/claude/ORDER_NUMBER_VARIANT_DESIGN.md` v1.0;
narrative in SESSION_HANDOVER.md "Session 66 Summary". **Adopted instead**
(implemented Session 67, reflected in the DONE section above): main order
number + variant concatenated into ONE `order_number` string at the external
DEC-database export stage (e.g. `"DELQA-00"` — every record carries an
explicit variant suffix, `"-00"` for base models); both descriptions
concatenated into ONE `description` field using `" | "` as the delimiter.
No schema split of either column.

---

## Category Help Pages Feature — Session 73 (IMPLEMENTED, code-complete, not yet tested/committed)

5 new owner-facing help pages, one per device/software category, added to
the existing generic `SiteText` subsystem (see "SiteText" in Data Model
Overview above). **No migration** — these are pure data (new `KNOWN_TEXTS`
entries) plus routes plus a nav link, following the exact pattern already
established by README/News/Barter Trade/Privacy.

### New keys, titles, routes

    Key                  Title                Route helper
    help_computers       Computers Help       help_computers_path
    help_peripherals     Peripherals Help     help_peripherals_path
    help_components      Components Help      help_components_path
    help_connections     Connections Help     help_connections_path
    help_software        Software Help        help_software_path

Admin-manageable via the existing admin "Texts" dropdown (Upload Text /
Download Text / Delete Text) — no changes needed there; all three admin
views iterate `SiteText::KNOWN_TEXTS`, so the 5 new entries appeared
automatically. Owner-facing: linked from the "Info" dropdown in
`common/_navigation.html.erb`, below a new divider separating them from the
4 pre-existing general-info links.

### Two pre-existing bugs found and fixed (Never-Guess — confirmed by reading
### the actual files, not assumed from the Session 20 changelog description)

1. **`decor/app/controllers/site_texts_controller.rb`** (owner-facing) had
   never been updated when Session 20 introduced `SiteText.title_for_key` /
   `KNOWN_TEXTS` as the single source of truth for page titles — that
   refactor only touched the admin controller. The owner-facing controller
   kept its own private `title_for_key` hash with only `"readme"`
   hardcoded, falling back to `key.titleize` for everything else. This
   happened to produce correct output for the 4 pre-existing keys purely by
   coincidence (`.titleize` of "news"/"barter_trade"/"privacy" all happen to
   match their configured titles). It would NOT have worked for the new
   pages — `"help_computers".titleize` → "Help Computers", not the intended
   "Computers Help". Fixed (v1.1) by deleting the private method and
   delegating to `SiteText.title_for_key`, matching the admin controller.
2. **`decor/app/controllers/admin/site_texts_controller.rb`**'s
   `url_for_key` was a hardcoded `case` statement mapping key → route
   helper — needing a manual edit every time a `KNOWN_TEXTS` entry was
   added (the same "touch N places, miss one" shape as the Session 64
   admin-nav-menu gap and the Session 68 documentation gap). Every existing
   route's `as:` name is identical to its key, so this was generalized
   (v1.3) to `send("#{key}_path")`, rescuing `NoMethodError` back to
   `root_path`. No future `KNOWN_TEXTS` addition should ever need to touch
   this file again for this purpose — only `site_text.rb` + `routes.rb`.

### Files delivered (7: 5 production, 2 test; 0 migrations)

    decor/app/models/site_text.rb                            v1.1 → v1.2
    decor/app/controllers/site_texts_controller.rb            v1.0 → v1.1
    decor/app/controllers/admin/site_texts_controller.rb      v1.2 → v1.3
    decor/config/routes.rb                                    v3.6 → v3.7
    decor/app/views/common/_navigation.html.erb                v2.4 → v2.5
    decor/test/controllers/admin/site_texts_controller_test.rb v1.1 → v1.2
    decor/test/controllers/site_texts_controller_test.rb      NEW (v1.0 —
      this controller had NO test coverage at all before this session,
      flagged per PROGRAMMING_GENERAL.md's mandatory Test Coverage Check
      while fixing the title_for_key bug in it)

**No changes needed** to `admin.html.erb` (Texts dropdown already generic
over `KNOWN_TEXTS`), the three `admin/site_texts/*.html.erb` views (already
`KNOWN_TEXTS`-driven), `db/schema.rb` (no migration), or `site_texts/
show.html.erb` (already fully generic over `@site_text`/`@title`).

### Open item raised during this session, not yet resolved

Whether `decor/app/helpers/application_helper.rb`'s `render_markdown` (or
equivalent) enables Redcarpet's `:with_toc_data` extension — required for
Markdown headers to get `id=` attributes, which in turn is required for
in-page anchor links (`[Trade Status](#trade-status)`) to actually work on
these help pages. Not confirmed either way this session — the helper file
was not reviewed. Worth checking during the manual browser check below if
any of the 5 new pages are written with an in-page table of contents.

### NOT YET DONE — required before this feature can be committed

    [ ] Place the 7 delivered files into the actual project (via the Session
        73 placement script)
    [ ] Upload actual Markdown content for the 5 new keys via Admin > Texts >
        Upload Text (pages currently show "== Empty ==" until content exists)
    [ ] bin/rails test
    [ ] bundle exec rubocop -A / bundle exec rubocop
    [ ] bin/brakeman --no-pager
    [ ] bundle exec bundle-audit check --update
    [ ] Manual browser check: all 5 new Info dropdown links; admin Upload/
        Download/Delete selectors show the 5 new entries; help_computers_path
        renders "Computers Help" as its heading (regression check for the
        title_for_key fix); confirm whether render_markdown supports header
        anchors (see "Open item" above) if any page needs a TOC
    [ ] git workflow: branch → commit → push → PR → CI → merge → deploy

---

## Owner Part Number Feature — Sessions 69–72 (IMPLEMENTED, migrated, tested, deployed)

**Session 69** was design-consultation only. **Session 70** received Ulli's
answers to all three open questions and implemented the feature in full —
11 of 12 planned files delivered in that session, with `schema.rb`
regeneration (the 12th item) completed once `bin/rails db:migrate` was
actually run. **Session 72** closed out the remaining pre-commit checklist
(an additional `bundle-audit` gem-CVE fix was needed to get CI green) and
merged/deployed the feature to `main` — see SESSION_HANDOVER.md "Session 72
Summary" for the full incident.

### Confirmed answers (Session 70) and how each was implemented

**1. Uniqueness scope — KEEP the existing model/type dimension.**
New combined uniqueness:
`(owner, computer_model, owner_part_number, serial_number)` for Computer,
`(owner, component_type, owner_part_number, serial_number)` for Component.
Implemented as a Rails `uniqueness: { scope: [...] }` validation on
`serial_number` (widened scope array) on both models, backed by a new
4-column unique DB index on each table (migration 20260716000200).

**2. Presence + defaulting — symmetric across both models and both fields.**
`Computer#serial_number` (already `presence: true`) and
`Component#serial_number` (previously `allow_blank: true` — REMOVED) both
now default to `"-"` via a `before_validation` callback when left blank
(never `before_save` — see RAILS_SPECIFICS.md "before_validation vs
before_save"). `owner_part_number` gets the identical treatment on both
models. This closes the asymmetry flagged in Session 69.

**3. Spares collision — one-time SQL backfill, Option B (no auto-assign).**
Migration 20260716000100 detects every `(owner_id, component_type_id)` group
with 2+ components sharing a blank/dash `serial_number`, and assigns each
member of a colliding group a distinct `"SPARE-#{component.id}"` placeholder
(component.id is already globally unique, so no per-group counter is
needed). This fixes ONLY the one-time backfill of pre-existing data.
**Confirmed: no auto-assign mechanism going forward** (Option B). Once
migration 20260716000200's constraint is live, a second unserialized spare
of the same type for the same owner is rejected at save time — the user
must supply a real distinguishing Owner Part Number or DEC Serial Number
themselves. This is a genuine, visible behaviour change for owners who
currently stack unlabeled spares, not just a schema detail.

**4. CSV export/import — owner_export_service.rb / owner_import_service.rb
only.** `computer_model_export_service.rb` confirmed OUT of scope — it
exports `ComputerModel` catalog/reference data (model names only), which
has no relationship to per-instance `owner_part_number` values; adding the
column there would have nowhere to attach. `owner_export_service.rb` v1.11
adds `owner_part_number` to both `COMPUTER_SECTION_HEADERS` and
`COMPONENT_SECTION_HEADERS`. `owner_import_service.rb` v1.12 reads the new
column (defaulting to `"-"` when absent, matching the model default) and
widens both duplicate-detection `exists?` checks to include it.

### Real behaviour change flagged from the import-side implementation (not asked, worth knowing)

Previously, `OwnerImportService` never deduplicated blank-serial component
rows at all (`if serial_number && exists?(...)` — the guard skipped the
check entirely when `serial_number` was blank), so re-importing a CSV with
several unserialized spares of the same type created a fresh row every
time. Now that both `serial_number` and `owner_part_number` normalize to
`"-"`, that guard was removed and the duplicate check is unconditional — a
second identical `"-"/"-"` spare row of the same type in a re-import is now
silently skipped as a duplicate, matching the same dedup behaviour
serialized components and computers already had. Direct, unavoidable
consequence of the Option B decision above. Worth a one-time check against
any CSV taken before this migration if Ulli re-imports historical
spare-heavy data.

### Files delivered Session 70 (11 of 12; schema.rb confirmed via migrate in Session 72)

    decor/db/migrate/20260716000100_add_owner_part_number_to_computers_and_components.rb  NEW
    decor/db/migrate/20260716000200_enforce_owner_part_number_constraints.rb              NEW
    decor/app/models/computer.rb                                       v2.1 → v2.2
    decor/app/models/component.rb                                      v1.5 → v1.6
    decor/app/controllers/computers_controller.rb                      v1.22 → v1.23
    decor/app/controllers/components_controller.rb                     v2.0 → v2.1
    decor/app/views/computers/_form.html.erb                           v2.6 → v2.7
    decor/app/views/components/_form.html.erb                          v1.11 → v1.12
    decor/app/services/owner_export_service.rb                        v1.10 → v1.11
    decor/app/services/owner_import_service.rb                        v1.11 → v1.12
    decor/test/fixtures/computers.yml                                  v1.9 → v1.10
    decor/test/fixtures/components.yml                                 v1.4 → v1.5

**12th item, Session 70 → confirmed Session 72:** `decor/db/schema.rb`
regeneration — required actually running `bin/rails db:migrate` against a
real database, which had not happened as of Session 70's close. This was
completed at the start of Session 72's git workflow (`db:migrate ok` per
Ulli), along with `bin/rails test`, `bin/rails test:system`, `bundle exec
rubocop -A`, and `bin/brakeman --no-pager` all passing before the branch was
pushed. The two-migration recreation logic — including the
`"SPARE-#{id}"` backfill in migration 1 — has now run successfully against
a real database with no reported issues.

### Scope notes — deliberately NOT touched this session (Session 70)

- The embedded Component sub-table inside `computers/_form.html.erb`
  (columns: Type | Description | Order No. | Serial No. | Condition |
  Trade) was left unchanged — it displays each Component's own fields via a
  separate association, and adding an Owner Part No. column there wasn't
  requested. Flag if wanted.
- No index/show page display views were touched (not requested, not
  provided this session) — Owner Part Number is only visible on the
  edit/new forms and in CSV export/import for now.

### Upload-collision lesson from this session — RESOLVED Session 71

`computers/_form.html.erb` and `components/_form.html.erb` share a bare
filename after browser dot-to-underscore mangling (`_form_html.erb`) —
uploading them in the same session (even across separate messages, since
the mangled name is IDENTICAL for both) meant the second upload silently
overwrote the first on disk mid-session, and the first file had to be
re-requested. COMMON_BEHAVIOR.md's old "Upload File Naming" rule covered
this in principle (upload same-named files in separate messages) but didn't
anticipate that Rails' `_form.html.erb` convention makes this collision
routine across this entire project (every resource has one). Formalized in
Session 71: COMMON_BEHAVIOR.md v3.0's "File Transfer Protocol —
Export/Import Scripts" replaces one-file-per-message with @-encoded flat
filenames, which structurally prevents this collision rather than relying
on upload ordering.

### NOT YET DONE — required before this feature can be committed

All items completed as of Session 72: migrated (`bin/rails db:migrate`),
tested (`bin/rails test`, `bin/rails test:system`), lint/security-scanned
(`bundle exec rubocop -A`, `bin/brakeman --no-pager`), and — after fixing an
unrelated `bundle-audit` CI failure on four gems (loofah,
rails-html-sanitizer, sqlite3, websocket-driver) — committed, pushed,
merged, and deployed via `kamal deploy`. See SESSION_HANDOVER.md "Session
72 Summary" for the complete incident detail.

---

## Appliances → Peripherals Merger — FULLY COMPLETE (Sessions 41–42)

- `appliance` (device_type=1) removed from enum on `Computer` and `ComputerModel`.
- Both enums now use hash form `{ computer: 0, peripheral: 2 }`.
- Import backward compat: CSV record_type `"appliance"` → mapped to `:peripheral`. Keep.

---

## Connections Feature — Status

    Part 1a: Migrations + models + fixtures             DONE (Session 31)
    Part 1b: Model tests                                DONE (Session 32)
    Part 2:  Admin ConnectionTypes CRUD                 DONE (Session 33)
    Part 3:  Owner device show pages — read-only        DONE (Sessions 34–35)
    Part 4:  Owner ConnectionGroup CRUD                 DONE (Session 36)
    Part 5:  owner_group_id / owner_member_id / labels  DONE (Sessions 38–39) ✓

---

## Known Issues & Solutions

### New admin:: resources require an admin.html.erb nav update — same session (Session 63/64)
Adding `resources :foo` inside `namespace :admin do ... end` in routes.rb does
NOT surface the feature anywhere. The admin menu bar lives in
`decor/app/views/layouts/admin.html.erb` (a separate layout from
`common/_navigation.html.erb`), with each top-level item being its own
dropdown `<div data-controller="dropdown">` block. Session 63 shipped the
Component Suggestions admin CRUD (controller, views, routes) without touching
this layout, leaving the feature invisible until the user reported it missing
in Session 64.
**Rule: any session that adds a new `admin::` resources block MUST also add
the corresponding `link_to` inside the matching dropdown in admin.html.erb
(or a new dropdown, if the resource doesn't fit an existing menu group),
before the session is considered complete — not as a follow-up.**

### CI Security (Ruby) failures — always confirm which tool, and confirm clean before pushing (Session 64, reinforced Session 72)
`CI/Security (Ruby)` is `bundle-audit` (gem-version CVE scan), NOT Brakeman
(static code scan) — two separate CI jobs. A clean local `bin/brakeman`
proves nothing about this check. Pull the actual CI log
(`gh run view <run-id> --log-failed`) before assuming which tool failed.
`bundle-audit` reports vulnerabilities in batches — fixing what one CI run
shows can unmask more on the next run. Always confirm with a full local
`bundle exec bundle-audit check --update` returning "No vulnerabilities
found" before re-pushing. Session 72 hit this again: four gems (loofah,
rails-html-sanitizer, sqlite3, websocket-driver) surfaced in a single batch
on the `feature/owner_part_number` PR.

### System tests — browser-layer login (Session 59)
`login_as` uses the Rack adapter. System tests require `sign_in` (browser form).
Never call `login_as` from a system test file.

### Manual data migrations — check ALL tables (Session 42)
Grep `db/schema.rb` for the column name to find all affected tables.

### Never Guess — Read the File or Ask (Session 39)
Claude must never invent a path helper, method name, or behaviour without reading
the actual file.

### enum hash form required after non-contiguous gap (Session 41)
`enum :device_type, { computer: 0, peripheral: 2 }, prefix: true`

### owner_group_id / owner_member_id — 0.present? is true (Session 38)
Guard must be `return if field.to_i > 0` not `return if field.present?`.

### data-turbo="false" disables Turbo on all descendants (Session 53)
A Turbo-method link inside a data-turbo="false" ancestor silently falls back to GET.

### CSS grid grid-cols-N causes nav link overflow (Session 53)
Use grid-cols-[auto_1fr_auto] for left/logo/right navbars.

---

## Design Patterns

### Color Scheme
- Clickable values:    `text-indigo-600 hover:text-indigo-900`
- Destructive actions: `text-red-600 hover:text-red-900`
- Non-clickable data:  `text-stone-600`
- Table headers:       `text-stone-500 uppercase`
- Barter offered:      `text-green-700`
- Barter wanted:       `text-amber-600`
- Barter no_barter:    `text-stone-400` (em-dash)

### Button Labels
- Primary: descriptive ("Update Computer", "Save Component")
- Secondary: "Done" — never "Cancel"

### UI Naming (Connections feature)
- "Connection Group" → "Connection" in all user-facing text
- "Connection Member" → "Port" in all user-facing text

### UI Terminology — Established Renames (Session 69)

**These are the current, correct UI labels. Any new form/view/table added in
future sessions MUST use the right-hand column — not the legacy left-hand
term — for these fields.** Attribute/column/route names are UNCHANGED;
only displayed text changed.

    Legacy UI label      Current UI label        Underlying attribute (unchanged)
    ────────────────────────────────────────────────────────────────────────────
    "Model"               "Computer Model"         computer_model_id / computer.computer_model
    "Order Number"        "DEC Part Number"         order_number
    "Serial Number"       "DEC Serial Number"       serial_number

**Compact/abbreviated headers** (narrow table columns) follow the same
mapping, abbreviated consistently:
    "Order" / "Order No."   → "DEC P/N" (owners/computers.html.erb, owners/peripherals.html.erb)
                               or "DEC Part No." (components/index.html.erb, owners/components.html.erb)
    "Serial" / "Serial No." → "DEC S/N" or "DEC Serial No." (same file-pairing as above)

**Scope confirmed with the user (Session 69):** this includes the Admin >
Component Suggestions screens and the Components dropdown menu items
("Re-validate DEC Part Numbers", "Download Unvalidated DEC Part Numbers") —
i.e. the rename applies project-wide to every place these concepts are
displayed to a user, not just the primary Computer/Component forms.

**Explicitly NOT renamed (still say "order_number"/"serial_number"):**
- CSV column headers and literal field-name references in
  `decor/app/views/data_transfers/show.html.erb` and
  `decor/app/views/admin/bulk_uploads/new.html.erb` — these are the actual
  import/export contract column names; renaming them would break CSV
  compatibility with existing exported files.
- The downloaded CSV filename in
  `decor/app/controllers/admin/component_order_numbers_controller.rb`
  (`unvalidated_order_numbers_<date>.csv`) — not yet addressed; flagged for
  the user to decide whether it's in scope.
- Ruby/JS identifiers, method names, route helpers, DB columns, and internal
  code comments describing *past* decisions (left as historical record).

---

## Quick Reference Commands

```bash
bin/rails server
bin/rails test
bin/rails test:system
bin/rails db:migrate
kamal app exec --reuse "bin/rails db:migrate"
kamal deploy
gh pr merge --merge --delete-branch
git pull
```

---

**End of DECOR_PROJECT.md**
