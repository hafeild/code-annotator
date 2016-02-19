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
  # get     'download' => 'projects#download'

  resources :users,         only: [:create,:update,:edit,:destroy]
  resources :projects,      only: [:index,:show,:create]
  resources :account_activations, only: [:edit]
  resources :email_verifications, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  post 'projects/:project_id/files'    => 'files#create'
  get  'projects/:project_id/download' => 'projects#download'

  ## For public link access.
  get 'projects/public/:link_uuid'          => 'projects#show_public'
  get 'projects/public/:link_uuid/download' => 'projects#download_public'

  ## For the JSON api.
  namespace :api do
    ## Projects.
    resources :projects 

    ## Files (by project).
    get   'projects/:project_id/files'    => 'files#index'
    post  'projects/:project_id/files'    => 'files#create_directory'
    # get   'projects/:project_id/download' => 'files#download'
    get   'projects/:project_id/print'    => 'files#print'
    resources :files,       only: [:show,:update,:destroy]

    ## For public link access to files.
    get 'projects/public/:link_uuid/files/:id'=> 'files#show_public'

    ## Permissions (by project).
    get   'projects/:project_id/permissions' => 'permissions#index'
    post  'projects/:project_id/permissions' => 'permissions#create'
    resources :permissions, only: [:show,:update,:destroy]

    ## Public link management (by project).
    get 'projects/:project_id/public_links'  => 'public_links#index'
    post 'projects/:project_id/public_links' => 'public_links#create'
    resources :public_links, only: [:show,:update,:destroy]

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
end
