require "cloudinary"

# Load Cloudinary configuration
Cloudinary.config_from_url(ENV["CLOUDINARY_URL"]) if ENV["CLOUDINARY_URL"].present?

# Or use the config file
if File.exist?(Rails.root.join("config", "cloudinary.yml"))
  # Process ERB in the YAML file (similar to database.yml)
  cloudinary_yml = ERB.new(File.read(Rails.root.join("config", "cloudinary.yml"))).result
  cloudinary_config = YAML.safe_load(cloudinary_yml, aliases: true)[Rails.env]

  if cloudinary_config
    Cloudinary.config do |config|
      config.cloud_name = cloudinary_config["cloud_name"]
      config.api_key = cloudinary_config["api_key"]
      config.api_secret = cloudinary_config["api_secret"]
      config.secure = cloudinary_config["secure"] || true
      config.cdn_subdomain = cloudinary_config["cdn_subdomain"] || true
    end
  end
end
