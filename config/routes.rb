Rails.application.routes.draw do

  ## Projects.
  resources :projects 

  ## Files (by project).
  get 'projects/:project_id/files' => 'files#index'
  get 'projects/:project_id/download' => 'files#download'
  get 'projects/:project_id/print' => 'files#print'
  post 'projects/:project_id/files' => 'files#create'
  resources :files,       only: [:show,:update,:destroy]

  ## Permissions (by project).
  get 'projects/:project_id/permissions' => 'permissions#index'
  post 'projects/:project_id/permissions' => 'permissions#create'
  resources :permissions, only: [:show,:update,:destroy]

  ## Annotations (by project and files).
  post 'projects/:project_id/comments' => 'comments#create'
  get 'projects/:project_id/comments' => 'comments#index'
  get 'projects/:project_id/files/:file_id/comments' => 'comments#index'
  resources :comments,    only: [:show,:update,:destroy]

  post 'projects/:project_id/altcode' => 'altcode#create'
  get 'projects/:project_id/altcode' => 'altcode#index'
  get 'projects/:project_id/files/:file_id/altcode' => 'altcode#index'
  resources :altcode,     only: [:show,:update,:destroy]



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'application#hello'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
