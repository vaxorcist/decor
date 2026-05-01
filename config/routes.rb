# decor/config/routes.rb
# version 3.1
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
