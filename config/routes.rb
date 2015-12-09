Rails.application.routes.draw do


  get 'password_resets/new'

  get 'password_resets/edit'

  root    'static_pages#home'
  get     'home'   => 'static_pages#home'
  get     'info'   => 'static_pages#information'
  get     'login'  => 'sessions#new'
  post    'login'  => 'sessions#create'
  delete  'logout' => 'sessions#destroy'
  get     'signup' => 'users#new'

  resources :users,         only: [:create,:update,:edit,:destroy]
  resources :projects,      only: [:index,:show]
  resources :account_activations, only: [:edit]
  resources :email_verifications, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  post  'projects/:project_id/files'    => 'files#create'

  ## For the JSON api.
  namespace :api do
    ## Projects.
    resources :projects 

    ## Files (by project).
    get   'projects/:project_id/files'    => 'files#index'
    post  'projects/:project_id/files'    => 'files#create_directory'
    get   'projects/:project_id/download' => 'files#download'
    get   'projects/:project_id/print'    => 'files#print'
    resources :files,       only: [:show,:update,:destroy]

    ## Permissions (by project).
    get   'projects/:project_id/permissions' => 'permissions#index'
    post  'projects/:project_id/permissions' => 'permissions#create'
    resources :permissions, only: [:show,:update,:destroy]

    ## Annotations (by project and files).
    ## Comments.
    post  'projects/:project_id/comments'                => 'comments#create'
    get   'projects/:project_id/comments'                => 'comments#index'
    get   'projects/:project_id/files/:file_id/comments' => 'comments#index'
    resources :comments,    only: [:show,:update,:destroy]

    ## Comment locations.
    post    'comments/:comment_id/locations'              => 
              'comment_locations#create'
    resources :comment_locations, only: [:destroy]

    ## Alternate code.
    post  'projects/:project_id/altcode'                => 'altcode#create'
    get   'projects/:project_id/altcode'                => 'altcode#index'
    get   'projects/:project_id/files/:file_id/altcode' => 'altcode#index'
    resources :altcode,     only: [:show,:update,:destroy]
  end


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
