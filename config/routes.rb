Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    # namespace :api → /api/...
    namespace :v1 do
      # namespace :v1 → /api/v1/...

      # Health check route
      get "health", to: "health#check"

      # Authentication routes
      post "auth/request_magic_link", to: "auth#request_magic_link"
      post "auth/verify_code", to: "auth#verify_code"
      get "auth/verify", to: "auth#verify_magic_link"
      get "auth/profile", to: "auth#profile"
      delete "auth/logout", to: "auth#logout"

      # Client routes
      resources :clients, except: [ :destroy ] do
        # GET /api/v1/clients → ClientsController#index
        # GET /api/v1/clients/:id → ClientsController#show
        # POST /api/v1/clients → ClientsController#create
        # PATCH /api/v1/clients/:id → ClientsController#update
        # PUT /api/v1/clients/:id → ClientsController#update
        collection do
          delete :bulk_delete # DELETE /api/v1/clients/bulk_delete → ClientsController#bulk_delete
        end
      end

      # Custom field routes
      resources :custom_fields

      # Gallery routes
      namespace :gallery do
        # Gallery images routes
        resources :galleries, only: [ :index, :show, :update ] do
          collection do
            post :upload         # POST /api/v1/gallery/galleries/upload
            delete :destroy      # DELETE /api/v1/gallery/galleries → GalleriesController#destroy (bulk delete)
          end
        end

        # Single image delete
        delete "galleries/:id", to: "galleries#destroy"  # DELETE /api/v1/gallery/galleries/:id

        # Folder routes
        resources :folders do
          member do
            post :add_image          # POST /api/v1/gallery/folders/:id/add_image
            delete :remove_images    # DELETE /api/v1/gallery/folders/:id/remove_images
            patch :set_cover_image   # PATCH /api/v1/gallery/folders/:id/set_cover_image
            post :share              # POST /api/v1/gallery/folders/:id/share
          end
        end
      end

      # Public folder routes (no authentication required)
      get "public/folders/:public_id", to: "public_folders#show"
      get "public/folders/:public_id/images", to: "public_folders#images"

      # User routes
      patch "users/profile", to: "users#update"
      put "users/profile", to: "users#update"
      patch "users/business_image", to: "users#update_business_image"
      put "users/business_image", to: "users#update_business_image"

      # Catch-all route for API endpoints not found
      match "*path", to: "application#not_found", via: :all
    end
  end

  # Catch-all route for non-API endpoints
  match "*path", to: "application#not_found", via: :all

  # Defines the root path route ("/")
  # root "posts#index"
end
