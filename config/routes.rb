Rails.application.routes.draw do
  resources :products do
    collection do
      post :sync_from_sheet
      post :sync_to_sheet
    end
  end
  root 'products#index'
end
