# decor/config/routes.rb
# version 1.3
# Added: resources :appliance_models pointing to the computer_models controller.
# The defaults: { device_context: "appliance" } param tells the controller
# which device type context it is operating in, without path-sniffing.
# computer_models also gets defaults: { device_context: "computer" } for symmetry.

Rails.application.routes.draw do
  default_url_options(host: Decor::Routes.host, protocol: Decor::Routes.protocol)

  root "home#index"

  resources :owners
  resources :computers
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

    # Computer Models and Appliance Models share the same controller.
    # The device_context default param tells the controller which type it
    # is serving; no path-sniffing or subclassing required.
    resources :computer_models,  only: %i[index new create edit update destroy],
                                 defaults: { device_context: "computer" }
    resources :appliance_models, only: %i[index new create edit update destroy],
                                 controller: "computer_models",
                                 defaults: { device_context: "appliance" }

    resources :conditions,            only: %i[index new create edit update destroy]
    resources :component_conditions,  only: %i[index new create edit update destroy]
    resources :run_statuses,          only: %i[index new create edit update destroy]
    resources :bulk_uploads,          only: %i[new create]
  end

  get "up" => "rails/health#show", as: :rails_health_check
  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?
end
