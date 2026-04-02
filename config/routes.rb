# decor/config/routes.rb
# version 2.8
# v2.8 (Session 45): Software feature Session C.
#   Added get :software to owners member block — /owners/:id/software sub-page.
#   Added resources :software_items, only: [:show] — individual item detail page.
#   Both are read-only (no create/edit/destroy until Session D).
# v2.7 (Session 44): Software feature Session B.
#   Added resources :software_names and :software_conditions in admin namespace.
# v2.6 (Session 41): Appliances → Peripherals merger Phase 2.
#   Removed get :appliances from owners member block (sub-page gone).
#   Removed resources :appliances top-level route (device_context "appliance" gone).
#   Removed resources :appliance_models from admin namespace (admin page gone).
#   Peripherals now covers all device_type_peripheral? records (formerly also appliances).
# v2.5: "/owners/:id/connections — connections table" added manually
# v2.4 (Session 36): Added resources :connection_groups nested under :owners.
# v2.3 (Session 33): Added admin :connection_types resource.
# v2.2 (Session 25): Added resources :peripherals index route.
# v2.1 (Session 25): Added admin :peripheral_models resource.
# v2.0 (Session 25): Added :peripherals member route under :owners.
# v1.9 (Session 24): Added admin data_transfer routes inside namespace :admin.
# v1.8 (Session 23): Added member routes under :owners (computers/appliances/components).
# v1.4 (Session 17): Added resources :appliances and device_context defaults.

Rails.application.routes.draw do
  default_url_options(host: Decor::Routes.host, protocol: Decor::Routes.protocol)

  root "home#index"

  # Public text pages — all served by site_texts#show (no login required).
  # The key default param selects the SiteText record to render.
  get "readme",       to: "site_texts#show", defaults: { key: "readme" },       as: :readme
  get "news",         to: "site_texts#show", defaults: { key: "news" },         as: :news
  get "barter_trade", to: "site_texts#show", defaults: { key: "barter_trade" }, as: :barter_trade
  get "privacy",      to: "site_texts#show", defaults: { key: "privacy" },      as: :privacy

  # Owner sub-pages: each shows one section of the owner's profile.
  # show remains the summary/profile card view.
  # connection_groups: full CRUD nested under the owner — owner_id in the URL
  # is always validated against Current.owner in the controller.
  resources :owners do
    member do
      get :computers    # /owners/:id/computers   — computers table
      get :peripherals  # /owners/:id/peripherals — peripherals table (device_type: peripheral)
      get :components   # /owners/:id/components  — components table
      get :connections  # /owners/:id/connections — connections table
      get :software     # /owners/:id/software    — software items table (Session 45)
    end
    # Full CRUD for connection groups; no :show (index suffices).
    resources :connection_groups, only: %i[index new create edit update destroy]
  end

  resources :computers,    defaults: { device_context: "computer" }

  # Peripherals index — shares the computers controller; device_context param
  # tells the controller to lock the device_type filter to "peripheral".
  # Peripherals covers all device_type_peripheral? records (formerly also appliances).
  resources :peripherals,  controller: "computers", only: [:index],
                           defaults: { device_context: "peripheral" }

  resources :components

  # Software items — read-only in Session C (show only).
  # create/edit/update/destroy will be added in Session D.
  # No device_context needed — SoftwareItem is not a Computer variant.
  resources :software_items, only: [:show]

  # Owner data export / import — always scoped to Current.owner (no id in URL).
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

    resources :conditions,            only: %i[index new create edit update destroy]
    resources :component_conditions,  only: %i[index new create edit update destroy]
    resources :run_statuses,          only: %i[index new create edit update destroy]
    resources :bulk_uploads,          only: %i[new create]

    # Software lookup tables — admin-managed, analogous to component_types /
    # component_conditions. Added Session 44 (Software feature Session B).
    resources :software_names,      only: %i[index new create edit update destroy]
    resources :software_conditions,  only: %i[index new create edit update destroy]

    # Site text management — generic upload and delete pages for all named texts.
    resources :site_texts, only: %i[new create destroy], param: :key do
      collection do
        get :delete_confirm
      end
    end

    # Admin data transfer — import/export of reference data and owner collections.
    get  "data_transfer",        to: "data_transfers#show",   as: :data_transfer
    get  "data_transfer/export", to: "data_transfers#export",  as: :export_data_transfer
    post "data_transfer/import", to: "data_transfers#import",  as: :import_data_transfer
  end

  get "up" => "rails/health#show", as: :rails_health_check
  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?
end
