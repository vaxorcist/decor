# decor/config/routes.rb
# version 3.9
# v3.9 (Session 90): Storage Locations show page. Ulli asked for a page at
#   /storage_locations/:id listing everything stored there (Computers,
#   Peripherals, Components, Software Items together, regardless of
#   category), reachable via a link on the location's name on the index
#   page. This reverses Session B's original "No :show action — a
#   StorageLocation carries only a name, so the index list is the only
#   display surface needed" decision (see the v3.8 note below, kept for
#   historical context) — that decision made sense before Session C added
#   the has_many :computers/:components/:software_items associations;
#   now that they exist, a show page is straightforward and useful.
#   Removed `except: [:show]` so :show becomes a normal RESTful action,
#   scoped to Current.owner in the controller exactly like every other
#   action on this resource (see storage_locations_controller.rb v1.2).
#   delete_confirm's member-route placement is unchanged.
# v3.8 (Session B, Storage Locations feature): Added resources :storage_locations,
#   except: [:show] (no show page — the index list is the only display surface;
#   a StorageLocation carries only a `name`, see storage_location.rb v1.0).
#   delete_confirm is a MEMBER route (get :delete_confirm inside member do),
#   NOT a collection route like admin/site_texts's delete_confirm — that one
#   lets the admin PICK which text to delete from a selector with no :id in
#   the URL; this one confirms deletion of ONE specific record the owner
#   already selected from their own index list, so it needs the :id.
#   Fully private/owner-scoped (no owners/:id nesting, no public visibility) —
#   see storage_locations_controller.rb v1.0 for the access model.
# v3.7 (Session 73): Category Help Pages feature.
#   Added 5 new public text-page routes, following the exact same pattern as
#   the 4 existing ones (readme/news/barter_trade/privacy): all served by
#   site_texts#show, `defaults: { key: ... }`, `as:` identical to the key
#   string. The `as:` == key convention is REQUIRED — admin/site_texts_
#   controller.rb v1.3's generalized url_for_key(key) does `send("#{key}_path")`
#   to redirect to the right public page after an upload, for ANY key,
#   without a per-key case branch. Breaking the as:-equals-key convention for
#   a future key would silently fall back that redirect to root_path.
#   New keys: help_computers, help_peripherals, help_components,
#   help_connections, help_software. See DECOR_PROJECT.md "Category Help
#   Pages Feature — Session 73" for full context.
# v3.6 (Session 67): Phase 4 item 2 — "Download Manual Changes" admin feature.
#   Added a `download_manual` collection route nested inside the existing
#   `resources :component_suggestions` block (namespace :admin). Because this
#   is a collection route on a `resources` block already inside
#   `namespace :admin`, Rails generates the path helper as
#   `admin_download_manual_component_suggestions_path` — "admin_" prefix (from
#   the namespace) + "download_manual_component_suggestions" (the standard
#   Rails collection-route naming: action + pluralized resource name).
#   Per RAILS_SPECIFICS.md "Named Routes (as:) Inside namespace — Still
#   Prefixed" (the Session 65 lesson), this MUST be verified against the
#   actual routes table before wiring up the admin.html.erb link:
#     bin/rails routes | grep download_manual
#   rather than assumed from this comment alone.
# v3.5 (Session 65): Component order_number bulk maintenance.
#   Added two admin-only routes, both non-resourceful (no CRUD, no :id param):
#     POST /admin/component_order_numbers/revalidate  — re-validate action
#     GET  /admin/component_order_numbers/unvalidated — CSV download action
#   Handled by Admin::ComponentOrderNumbersController. Both live under
#   namespace :admin (admin-only maintenance operating across ALL components/
#   ALL owners — not owner-scoped, matching the component_suggestions pattern).
# v3.4 (Session 64): Component Suggestions Phase 2.
#   Added owner-facing GET /component_suggestions route for typeahead JSON endpoint.
#   Handled by ComponentSuggestionsController#index (NOT under admin namespace).
#   Requires login (require_login in controller). Returns JSON only.
# v3.3 (Session 63): Component Suggestions Phase 1.
#   Added resources :component_suggestions under namespace :admin.
#   Actions: index, new, create, edit, update, destroy.
# v3.2 (Session 61): Added computer_statistics route.
#   GET /computer_statistics → computer_statistics#index
#   Displays a table of computer models with their registered-computer counts.
#   Supports sort param: most_common (default), least_common, model_asc, model_desc.
# v3.1 (Session 56): Newsletter feature.
#   Added resources :newsletters inside namespace :admin.
#   Actions: index, new, create, show, destroy.
#   Plus member routes for send_newsletter (GET + POST).
#   GET  /admin/newsletters/:id/send_newsletter — recipient-selection form.
#   POST /admin/newsletters/:id/send_newsletter — enqueue delivery.
# v3.0 (Session 53): Admin Texts — added Download option.
# v2.9 (Session 46): Expanded resources :software_items to full CRUD.
# v2.8 (Session 45): Added get :software to owners member block.
# v2.7 (Session 44): Added resources :software_names and :software_conditions.
# v2.6 (Session 41): Appliances → Peripherals merger Phase 2.
# v2.5: connections sub-page.
# v2.4 (Session 36): Added resources :connection_groups nested under :owners.
# v2.3 (Session 33): Added admin :connection_types resource.
# v2.2 (Session 25): Added resources :peripherals index route.
# v2.1 (Session 25): Added admin :peripheral_models resource.
# v2.0 (Session 25): Added :peripherals member route under :owners.
# v1.9 (Session 24): Added admin data_transfer routes inside namespace :admin.
# v1.8 (Session 23): Added member routes under :owners.
# v1.4 (Session 17): Added resources :appliances and device_context defaults.

Rails.application.routes.draw do
  default_url_options(host: Decor::Routes.host, protocol: Decor::Routes.protocol)

  root "home#index"

  # Public text pages — all served by site_texts#show (no login required).
  get "readme",       to: "site_texts#show", defaults: { key: "readme" },       as: :readme
  get "news",         to: "site_texts#show", defaults: { key: "news" },         as: :news
  get "barter_trade", to: "site_texts#show", defaults: { key: "barter_trade" }, as: :barter_trade
  get "privacy",      to: "site_texts#show", defaults: { key: "privacy" },      as: :privacy

  # Category Help Pages — added Session 73. Same site_texts#show pattern as
  # above. `as:` MUST equal the key string (see v3.7 changelog note above) —
  # admin/site_texts_controller.rb's url_for_key relies on it.
  get "help_computers",   to: "site_texts#show", defaults: { key: "help_computers" },   as: :help_computers
  get "help_peripherals", to: "site_texts#show", defaults: { key: "help_peripherals" }, as: :help_peripherals
  get "help_components",  to: "site_texts#show", defaults: { key: "help_components" },  as: :help_components
  get "help_connections", to: "site_texts#show", defaults: { key: "help_connections" }, as: :help_connections
  get "help_software",    to: "site_texts#show", defaults: { key: "help_software" },    as: :help_software

  # Statistics pages — public, no login required.
  # computer_statistics: counts of registered computers per computer model.
  get "computer_statistics", to: "computer_statistics#index", as: :computer_statistics

  # Component Suggestions typeahead endpoint — members only (require_login in controller).
  # Returns JSON array of { order_number, description, category } matching ?query=...
  # Used by the component_suggestion Stimulus controller on the components form.
  get "component_suggestions", to: "component_suggestions#index", as: :component_suggestions

  # Owner sub-pages: each shows one section of the owner's profile.
  # show remains the summary/profile card view.
  resources :owners do
    member do
      get :computers    # /owners/:id/computers
      get :peripherals  # /owners/:id/peripherals
      get :components   # /owners/:id/components
      get :connections  # /owners/:id/connections
      get :software     # /owners/:id/software
    end
    resources :connection_groups, only: %i[index new create edit update destroy]
  end

  resources :computers,   defaults: { device_context: "computer" }

  # Peripherals index — shares the computers controller.
  resources :peripherals, controller: "computers", only: [:index],
                          defaults: { device_context: "peripheral" }

  resources :components

  # Software items — full CRUD added in Session D.
  resources :software_items

  # Storage Locations — added Session B (Storage Locations feature).
  # Fully private, owner-scoped (see storage_locations_controller.rb v1.2) —
  # NOT nested under owners/:id, since there is no public/other-owner view of
  # this resource at all; the controller scopes every action to Current.owner
  # internally instead.
  # :show added Session 90 — lists everything stored at this location
  # (Computers/Peripherals/Components/Software Items combined, sorted
  # alphabetically), linked from the name on the index page. Reverses
  # Session B's original "no show page needed" decision now that Session C's
  # has_many associations make it easy to build.
  # delete_confirm is a MEMBER route (confirms ONE specific record already
  # selected from the index), unlike admin/site_texts's delete_confirm
  # (a collection route letting the admin pick which record from a selector).
  resources :storage_locations do
    member do
      get :delete_confirm
    end
  end

  # Owner data export / import.
  get  "data_transfer",        to: "data_transfers#show",   as: :data_transfer
  get  "data_transfer/export", to: "data_transfers#export",  as: :export_data_transfer
  post "data_transfer/import", to: "data_transfers#import",  as: :import_data_transfer

  resource :session, only: %i[new create destroy]
  resources :password_resets, only: %i[new create edit update], param: :token

  namespace :admin do
    resources :owners, only: %i[index edit update destroy] do
      post :send_password_reset, on: :member
    end
    resources :invites, only: %i[index new create destroy]
    resources :component_types,    only: %i[index new create edit update destroy]
    resources :connection_types,   only: %i[index new create edit update destroy]

    resources :computer_models,   only: %i[index new create edit update destroy],
                                  defaults: { device_context: "computer" }
    resources :peripheral_models, only: %i[index new create edit update destroy],
                                  controller: "computer_models",
                                  defaults: { device_context: "peripheral" }

    resources :conditions,           only: %i[index new create edit update destroy]
    resources :component_conditions, only: %i[index new create edit update destroy]
    resources :run_statuses,         only: %i[index new create edit update destroy]
    resources :bulk_uploads,         only: %i[new create]

    # Software lookup tables — admin-managed. Added Session 44.
    resources :software_names,      only: %i[index new create edit update destroy]
    resources :software_conditions, only: %i[index new create edit update destroy]

    # Component Suggestions — admin-managed typeahead lookup table. Added Session 63.
    # Powers the order_number autocomplete on the components form (Phase 2).
    #
    # download_manual — added Session 67 (Phase 4 item 2). Collection route
    # (no :id — operates across all manually-flagged rows at once), so it
    # lives in the `collection do ... end` block rather than `member do`.
    # Generates admin_download_manual_component_suggestions_path — VERIFY with
    # `bin/rails routes | grep download_manual` before wiring the admin.html.erb
    # link, per the Session 65 "Named Routes Inside namespace" lesson.
    resources :component_suggestions, only: %i[index new create edit update destroy] do
      collection do
        get :download_manual
      end
    end

    # Component order_number bulk maintenance — added Session 65.
    # Not a resourceful CRUD controller — just two standalone maintenance actions
    # operating across ALL Component records (reference-data maintenance, same
    # scope pattern as component_suggestions above).
    #   revalidate:   POST — re-syncs Component#order_number_verified for every
    #                 component against the current component_suggestions table.
    #                 Runs immediately; no preview step (confirmed design decision).
    #   unvalidated:  GET  — streams a CSV of components whose order_number is
    #                 present but order_number_verified is false. One row per
    #                 component (confirmed design decision — not deduplicated).
    post "component_order_numbers/revalidate",  to: "component_order_numbers#revalidate",
                                                 as: :revalidate_component_order_numbers
    get  "component_order_numbers/unvalidated", to: "component_order_numbers#unvalidated",
                                                 as: :unvalidated_component_order_numbers

    # Newsletters — added Session 56.
    # index:    list stored newsletters.
    # new/create: upload an .md file + subject, render HTML, save.
    # show:     preview rendered HTML body.
    # destroy:  delete a newsletter record.
    # send_newsletter (GET):  recipient-selection form.
    # send_newsletter (POST): enqueue delivery via NewsletterMailer.
    resources :newsletters, only: %i[index new create show destroy] do
      member do
        get  :send_newsletter
        post :send_newsletter
      end
    end

    resources :site_texts, only: %i[new create destroy], param: :key do
      collection do
        get :delete_confirm
        get :download_confirm
      end
      member do
        get :download
      end
    end

    get  "data_transfer",        to: "data_transfers#show",   as: :data_transfer
    get  "data_transfer/export", to: "data_transfers#export",  as: :export_data_transfer
    post "data_transfer/import", to: "data_transfers#import",  as: :import_data_transfer
  end

  get "up" => "rails/health#show", as: :rails_health_check
  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?
end
