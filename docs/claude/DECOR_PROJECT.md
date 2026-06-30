# decor/docs/claude/DECOR_PROJECT.md
# version 2.55
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

**Last Updated:** June 30, 2026 (Session 64 — Component Suggestions Phase 2 + admin nav fix; v2.55)
**Current Status:** Sessions 1–60 committed, pushed, merged, deployed.

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
│   │   ├── components_controller.rb                    ← Session 64 (v2.0)
│   │   ├── computers_controller.rb                     ← Session 52 (v1.22)
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
│   │   ├── component_suggestion.rb                    ← Session 63 (v1.0) NEW
│   │   ├── computer.rb                                 ← Session 43 (v2.1)
│   │   ├── computer_model.rb                          ← Session 41 (v1.3)
│   │   ├── newsletter.rb
│   │   ├── owner.rb                                   ← Session 43 (v1.5)
│   │   ├── software_condition.rb                      ← Session 43 (v1.0) NEW
│   │   ├── software_item.rb                           ← Session 43 (v1.0) NEW
│   │   └── software_name.rb                           ← Session 43 (v1.0) NEW
│   ├── services/
│   │   ├── all_owners_export_service.rb               ← Session 50 (v1.1)
│   │   ├── component_suggestion_export_service.rb     ← Session 63 (v1.0) NEW
│   │   ├── component_suggestion_import_service.rb     ← Session 63 (v1.0) NEW
│   │   ├── owner_export_service.rb                     ← Session 49 (v1.10)
│   │   └── owner_import_service.rb                     ← Session 49 (v1.11)
│   └── views/
│       ├── admin/
│       │   ├── component_conditions/
│       │   │   └── _form.html.erb                     ← Session 58 (v1.2)
│       │   ├── component_suggestions/                  ← Session 63 NEW
│       │   │   ├── _form.html.erb                     ← Session 63 (v1.0) NEW
│       │   │   ├── edit.html.erb                      ← Session 63 (v1.0) NEW
│       │   │   ├── index.html.erb                     ← Session 63 (v1.0) NEW
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
│       │   └── _navigation.html.erb                   ← Session 53 (v2.2)
│       ├── data_transfers/
│       │   └── show.html.erb                          ← Session 49 (v1.9)
│       ├── home/
│       │   └── index.html.erb                         ← Session 51 (v4.4)
│       ├── layouts/
│       │   └── admin.html.erb                         ← Session 53 (v2.2)
│       ├── computers/
│       │   └── show.html.erb                          ← Session 47 (v2.2)
│       ├── owners/
│       │   ├── _owner.html.erb                        ← Session 41 (v3.5)
│       │   ├── computers.html.erb                     ← Session 45 (v1.4)
│       │   ├── components.html.erb                    ← Session 45 (v1.4)
│       │   ├── connections.html.erb                   ← Session 45 (v1.2)
│       │   ├── peripherals.html.erb                   ← Session 45 (v1.3)
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
│   └── routes.rb                                      ← Session 63 (v3.3)
├── db/
│   └── migrate/
│       ├── 20260401000000_create_software_names.rb    ← Session 43 (v1.0) NEW
│       ├── 20260401000100_create_software_conditions.rb ← Session 43 (v1.0) NEW
│       ├── 20260401000200_create_software_items.rb    ← Session 43 (v1.0) NEW
│       ├── 20260511000100_create_component_suggestions.rb ← Session 63 (v1.0) NEW
│       └── 20260511000200_add_order_number_verified_to_components.rb ← Session 63 (v1.0) NEW
└── test/
    ├── controllers/
    │   ├── admin/
    │   │   ├── component_suggestions_controller_test.rb ← Session 63 (v1.0) NEW
    │   │   ├── computer_models_controller_test.rb      ← Session 41 (v1.3)
    │   │   ├── data_transfers_controller_test.rb       ← Session 50 (v1.3)
    │   │   ├── newsletters_controller_test.rb          ← Session 58 (v1.0) NEW
    │   │   ├── owners_controller_test.rb               ← Session 58 (v1.3)
    │   │   ├── site_texts_controller_test.rb           ← Session 53 (v1.1)
    │   │   ├── software_conditions_controller_test.rb  ← Session 44 (v1.0) NEW
    │   │   └── software_names_controller_test.rb       ← Session 44 (v1.0) NEW
    │   ├── computers_controller_test.rb                ← Session 59 (v1.11)
    │   ├── connection_groups_controller_test.rb        ← Session 38 (v1.1)
    │   ├── data_transfers_controller_test.rb           ← Session 50 (v1.4)
    │   ├── owners_controller_test.rb                  ← Session 58 (v2.0)
    │   └── software_items_controller_test.rb          ← Session 50 (v1.5)
    ├── fixtures/
    │   ├── computer_models.yml                         ← Session 41 (v1.3)
    │   ├── computers.yml                              ← Session 41 (v1.9)
    │   ├── newsletters.yml                            ← Session 58 (v1.0) NEW
    │   ├── owners.yml                                 ← Session 58 (v2.2)
    │   ├── software_conditions.yml                    ← Session 43 (v1.0) NEW
    │   ├── software_items.yml                         ← Session 43 (v1.0) NEW
    │   ├── component_suggestions.yml                  ← Session 63 (v1.0) NEW
    │   ├── software_conditions.yml                    ← Session 43 (v1.0) NEW
    │   ├── software_items.yml                         ← Session 43 (v1.0) NEW
    │   └── software_names.yml                         ← Session 43 (v1.0) NEW
    ├── mailers/
    │   └── newsletter_mailer_test.rb                  ← Session 58 (v1.0) NEW
    ├── models/
    │   ├── computer_model_test.rb                     ← Session 41 (v1.3)
    │   ├── computer_test.rb                           ← Session 41 (v1.7)
    │   ├── newsletter_test.rb                         ← Session 58 (v1.1) NEW
    │   ├── owner_test.rb                              ← Session 58 (v1.5)
    │   ├── software_condition_test.rb                 ← Session 43 (v1.0) NEW
    │   ├── software_item_test.rb                      ← Session 43 (v1.0) NEW
    │   ├── component_suggestion_test.rb                ← Session 63 (v1.0) NEW
    │   ├── software_condition_test.rb                 ← Session 43 (v1.0) NEW
    │   ├── software_item_test.rb                      ← Session 43 (v1.0) NEW
    │   └── software_name_test.rb                      ← Session 43 (v1.0) NEW
    ├── services/
    │   ├── component_suggestion_export_service_test.rb ← Session 63 (v1.0) NEW
    │   ├── component_suggestion_import_service_test.rb ← Session 63 (v1.0) NEW
    │   ├── computer_model_export_service_test.rb      ← Session 41 (v1.2)
    │   ├── computer_model_import_service_test.rb      ← Session 41 (v1.2)
    │   ├── owner_export_service_test.rb               ← Session 49 (v2.0)
    │   └── owner_import_service_test.rb               ← Session 49 (v1.7)
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

---

**Key file versions** (updated each session):

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

### ComponentSuggestion  ← Session 63 (Phase 1)
- Admin-managed lookup table for component order number autocomplete
- validates :order_number, presence: true, uniqueness: true, length max 20
- validates :description, length max 100, optional
- validates :category, length max 40, optional (free text; informational display only)
- order_number VARCHAR(20) NOT NULL, UNIQUE index
- description  VARCHAR(100) nullable
- category     VARCHAR(40)  nullable (NOT stored on component when suggestion accepted)
- scope :matching, ->(q) { where("order_number LIKE ?", "#{q}%").order(:order_number) }

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
