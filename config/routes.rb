# decor/config/routes.rb
# version 1.2
# Added: data_transfer routes for owner export/import feature

Rails.application.routes.draw do
  default_url_options(host: Decor::Routes.host, protocol: Decor::Routes.protocol)

  root "home#index"

  resources :owners
  resources :computers
  resources :components

  # Owner data export / import — always scoped to Current.owner (no id in URL).
  # Three named routes rather than a resource block because export is a GET that
  # streams a file download, which does not map neatly to a standard REST verb.
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
    resources :computer_models, only: %i[index new create edit update destroy]
    resources :conditions, only: %i[index new create edit update destroy]
    resources :component_conditions, only: %i[index new create edit update destroy]
    resources :run_statuses, only: %i[index new create edit update destroy]
    resources :bulk_uploads, only: %i[new create]
  end

  get "up" => "rails/health#show", as: :rails_health_check
  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?
end
