require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TailorApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Rails lets DATABASE_URL override config/database.yml for the primary database.
    # A leftover Postgres URL would silently replace SQLite/Turso, so move it aside;
    # db:import_from_postgres reads it from POSTGRES_DATABASE_URL.
    if ENV["DATABASE_URL"].to_s.start_with?("postgres")
      ENV["POSTGRES_DATABASE_URL"] = ENV["DATABASE_URL"] if ENV["POSTGRES_DATABASE_URL"].blank?
      ENV.delete("DATABASE_URL")
    elsif ENV["DATABASE_URL"]&.strip&.empty?
      ENV.delete("DATABASE_URL")
    end
  end
end
