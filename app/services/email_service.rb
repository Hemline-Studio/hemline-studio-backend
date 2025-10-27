require "mail"

class EmailService
  # Gmail SMTP configuration
  SMTP_SETTINGS = {
    address: "smtp.gmail.com",
    port: 587,
    domain: "gmail.com",
    user_name: ENV["GMAIL_USERNAME"],
    password: ENV["GMAIL_APP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }.freeze

  def self.send_magic_link(user, auth_code, base_url = nil)
    base_url ||= ENV["CLIENT_BASE_URL"] || "http://localhost:3000"
    magic_link = auth_code.magic_link(base_url)

    # Fallback greeting when first/last name may be blank
    display_name = if user.first_name.present? || user.last_name.present?
      user.full_name.strip
    else
      user.email
    end

    # Prepare template data
    template_data = {
      user_name: display_name,
      auth_code: auth_code.code,
      magic_link: magic_link,
      expiry_minutes: 15,
      title: "Hemline Auth - Magic Link"
    }

    # Send email with HTML template
    send_email(
      to: user.email,
      subject: "Your magic link to sign in 🎉",
      template: :magic_link,
      data: template_data
    )

    # Return success
    {
      success: true,
      message: "Magic link sent successfully 🎉",
      magic_link: magic_link,
      code: auth_code.code
    }
  rescue StandardError => e
    Rails.logger.error "Email sending failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    {
      success: false,
      message: "Failed to send email: #{e.message}"
    }
  end

  def self.send_welcome_email(user, base_url = nil)
    base_url ||= ENV["CLIENT_BASE_URL"] || "http://localhost:3000"
    # Fallback greeting when first/last name may be blank
    display_name = if user.first_name.present? || user.last_name.present?
      user.full_name.strip
    else
      user.email
    end

    # Prepare template data
    template_data = {
      user_name: display_name,
      title: "Hemline - Welcome Email"
    }

    # Send email with HTML template
    send_email(
      to: user.email,
      subject: "Welcome to Hemline 🎉",
      template: :welcome_email,
      data: template_data
    )

    # Return success
    {
      success: true,
      message: "Welcome email sent successfully 🎉"
    }
  rescue StandardError => e
    Rails.logger.error "Welcome email sending failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    {
      success: false,
      message: "Failed to send welcome email: #{e.message}"
    }
  end

  def self.send_folder_share_email(to:, folder:, user:, recipient_name: nil, base_url: nil)
    base_url ||= ENV["CLIENT_BASE_URL"] || "http://localhost:3000"
    # Prepare sender name
    sender_name = if user.first_name.present? || user.last_name.present?
      user.full_name.strip
    else
      user.email
    end

    # Prepare template data
    template_data = {
      recipient_name: recipient_name,
      sender_name: sender_name,
      sender_business: user.business_name,
      folder_name: folder.name,
      folder_description: folder.description,
      folder_url: folder.public_url(base_url),
      image_count: folder.image_count
    }

    # Send email with HTML template
    send_email(
      to: to,
      subject: "#{sender_name} shared a folder with you 📁",
      template: :folder_share,
      data: template_data
    )

    # Return success
    {
      success: true,
      message: "Folder share email sent successfully"
    }
  rescue StandardError => e
    Rails.logger.error "Folder share email sending failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    {
      success: false,
      message: "Failed to send folder share email: #{e.message}"
    }
  end

  # Generic method to send emails with HTML templates
  def self.send_email(to:, subject:, template:, data: {})
    # Validate environment variables
    unless ENV["GMAIL_USERNAME"].present? && ENV["GMAIL_APP_PASSWORD"].present?
      error_msg = "Email configuration missing: GMAIL_USERNAME or GMAIL_APP_PASSWORD not set"
      Rails.logger.error error_msg
      raise StandardError, error_msg
    end

    # Get HTML content from template
    html_body = render_template(template, data)

    # Configure mail with Gmail SMTP
    Mail.defaults do
      delivery_method :smtp, SMTP_SETTINGS
    end

    # Create and send the email
    mail = Mail.new do
      from     ENV["GMAIL_USERNAME"] || "hello@hemline.app"
      to       to
      subject  subject

      html_part do
        content_type "text/html; charset=UTF-8"
        body html_body
      end
    end

    if Rails.env.development?
      # Log email in development
      Rails.logger.info "=== EMAIL SENT ==="
      Rails.logger.info "To: #{to}"
      Rails.logger.info "Subject: #{subject}"
      Rails.logger.info "Template: #{template}"
      Rails.logger.info "=================="
    end

    # Send the email
    mail.deliver!

    Rails.logger.info "Email sent successfully to #{to}" if Rails.env.production?

    true
  rescue StandardError => e
    Rails.logger.error "Failed to send email to #{to}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.production?
    raise
  end

  # Render HTML template with data
  def self.render_template(template_name, data)
    template_path = Rails.root.join("app", "views", "email_templates", "#{template_name}.html.erb")

    unless File.exist?(template_path)
      raise "Email template not found: #{template_path}"
    end

    template_content = File.read(template_path)
    erb_template = ERB.new(template_content)

    # Create a binding with the data
    binding_obj = create_binding_with_data(data)

    erb_template.result(binding_obj)
  end

  private

  # Helper to create a binding with data variables
  def self.create_binding_with_data(data)
    obj = Object.new

    data.each do |key, value|
      obj.instance_variable_set("@#{key}", value)
      obj.define_singleton_method(key) { instance_variable_get("@#{key}") }
    end

    obj.instance_eval { binding }
  end
end
