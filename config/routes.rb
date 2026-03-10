# decor/config/routes.rb
# version 1.9
# v1.9 (Session 24): Added admin data_transfer routes inside namespace :admin.
#   GET  /admin/data_transfer        → admin/data_transfers#show   (admin_data_transfer_path)
#   GET  /admin/data_transfer/export → admin/data_transfers#export (export_admin_data_transfer_path)
#   POST /admin/data_transfer/import → admin/data_transfers#import (import_admin_data_transfer_path)
#   Mirrors the non-admin data_transfer route pattern (root-level, flat, singular resource).
# v1.8 (Session 23): Added member routes under :owners for the three sub-pages:
#   GET /owners/:id/computers  → owners#computers  (computers_owner_path)
#   GET /owners/:id/appliances → owners#appliances (appliances_owner_path)
#   GET /owners/:id/components → owners#components (components_owner_path)
#   The owners#show action now renders a compact summary card view; the three
#   sub-pages each show a single section (computers / appliances / components).
# v1.7 (Session 20): Added delete_confirm collection route under admin/site_texts.
# v1.6 (Session 20): Added news, barter_trade, privacy public routes.
# v1.5 (Session 18): Added public readme route and admin site_texts resource.
# v1.4 (Session 17): Added resources :appliances and device_context defaults.
# v1.3: resources :appliance_models pointing to the computer_models controller.

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
  resources :owners do
    member do
      get :computers   # /owners/:id/computers  — computers table
      get :appliances  # /owners/:id/appliances — appliances table
      get :components  # /owners/:id/components — components table
    end
  end

  resources :computers,  defaults: { device_context: "computer" }

  # Appliances index — shares the computers controller; device_context param
  # tells the controller to lock the device_type filter to "appliance".
  resources :appliances, controller: "computers", only: [:index],
                         defaults: { device_context: "appliance" }

  resources :components

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
    resources :component_types, only: %i[index new create edit update destroy]

    resources :computer_models,  only: %i[index new create edit update destroy],
                                 defaults: { device_context: "computer" }
    resources :appliance_models, only: %i[index new create edit update destroy],
                                 controller: "computer_models",
                                 defaults: { device_context: "appliance" }

    resources :conditions,            only: %i[index new create edit update destroy]
    resources :component_conditions,  only: %i[index new create edit update destroy]
    resources :run_statuses,          only: %i[index new create edit update destroy]
    resources :bulk_uploads,          only: %i[new create]

    # Site text management — generic upload and delete pages for all named texts.
    # delete_confirm: GET /admin/site_texts/delete_confirm — key selector page;
    #   actual destroy uses DELETE /admin/site_texts/:key (param: :key).
    resources :site_texts, only: %i[new create destroy], param: :key do
      collection do
        get :delete_confirm
      end
    end

    # Admin data transfer — import/export of reference data and owner collections.
    # Mirrors the non-admin data_transfer route pattern: flat singular-resource style.
    # Scoped to the admin namespace so requires admin login via Admin::BaseController.
    # Route helpers:
    #   admin_data_transfer_path         — show page (selector UI)
    #   export_admin_data_transfer_path  — export action (GET, returns CSV)
    #   import_admin_data_transfer_path  — import action (POST, accepts CSV upload)
    get  "data_transfer",        to: "data_transfers#show",   as: :data_transfer
    get  "data_transfer/export", to: "data_transfers#export",  as: :export_data_transfer
    post "data_transfer/import", to: "data_transfers#import",  as: :import_data_transfer
  end

  get "up" => "rails/health#show", as: :rails_health_check
  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?
end
