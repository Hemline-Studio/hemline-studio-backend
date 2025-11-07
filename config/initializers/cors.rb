# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow specific origins based on environment
    if Rails.env.production?
      origins "https://hemline-frontend.vercel.app",
              "https://hemline.studio",
              "https://www.hemline.studio",
              /https:\/\/.*\.vercel\.app$/  # Allow all Vercel preview deployments
    else
      # In development, allow localhost with different ports
      origins "http://localhost:3000",
              "http://localhost:3001",
              "http://localhost:5173",
              "http://127.0.0.1:3000",
              "http://127.0.0.1:3001",
              "http://127.0.0.1:5173"
    end

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: false,
      expose: [ "Authorization" ],
      max_age: 600
  end
end
