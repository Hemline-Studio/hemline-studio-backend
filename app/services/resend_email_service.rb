require "resend"

class ResendEmailService
  # Configure Resend client
  def self.client
    @client ||= begin
      unless ENV["RESEND_API_KEY"].present?
        error_msg = "Resend API key not configured. Set RESEND_API_KEY environment variable."
        Rails.logger.error error_msg
        raise StandardError, error_msg
      end
      
      Resend.api_key = ENV["RESEND_API_KEY"]
      Resend
    end
  end

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

    # Render HTML template
    html_body = EmailService.render_template(:magic_link, template_data)

    # Send email via Resend
    send_email(
      to: user.email,
      from: ENV["RESEND_FROM_EMAIL"] || "Hemline <onboarding@resend.dev>",
      subject: "Your magic link to sign in 🎉",
      html: html_body
    )

    # Return success
    {
      success: true,
      message: "Magic link sent successfully 🎉",
      magic_link: magic_link,
      code: auth_code.code
    }
  rescue StandardError => e
    Rails.logger.error "Resend email sending failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    {
      success: false,
      message: "Failed to send email: #{e.message}"
    }
  end

  def self.send_welcome_email(user, base_url = nil)
    base_url ||= ENV["CLIENT_BASE_URL"] || "http://localhost:3000"
    
    display_name = if user.first_name.present? || user.last_name.present?
      user.full_name.strip
    else
      user.email
    end

    template_data = {
      user_name: display_name,
      title: "Hemline - Welcome Email"
    }

    html_body = EmailService.render_template(:welcome_email, template_data)

    send_email(
      to: user.email,
      from: ENV["RESEND_FROM_EMAIL"] || "Hemline <onboarding@resend.dev>",
      subject: "Welcome to Hemline 🎉",
      html: html_body
    )

    {
      success: true,
      message: "Welcome email sent successfully 🎉"
    }
  rescue StandardError => e
    Rails.logger.error "Resend welcome email failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    {
      success: false,
      message: "Failed to send welcome email: #{e.message}"
    }
  end

  def self.send_folder_share_email(to:, folder:, user:, recipient_name: nil, base_url: nil)
    base_url ||= ENV["CLIENT_BASE_URL"] || "http://localhost:3000"
    
    sender_name = if user.first_name.present? || user.last_name.present?
      user.full_name.strip
    else
      user.email
    end

    template_data = {
      recipient_name: recipient_name,
      sender_name: sender_name,
      sender_business: user.business_name,
      folder_name: folder.name,
      folder_description: folder.description,
      folder_url: folder.public_url(base_url),
      image_count: folder.image_count
    }

    html_body = EmailService.render_template(:folder_share, template_data)

    send_email(
      to: to,
      from: ENV["RESEND_FROM_EMAIL"] || "Hemline <onboarding@resend.dev>",
      subject: "#{sender_name} shared a folder with you 📁",
      html: html_body
    )

    {
      success: true,
      message: "Folder share email sent successfully"
    }
  rescue StandardError => e
    Rails.logger.error "Resend folder share email failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    {
      success: false,
      message: "Failed to send folder share email: #{e.message}"
    }
  end

  private

  def self.send_email(to:, from:, subject:, html:)
    # Initialize client (validates API key)
    client

    # Send email using Resend gem
    params = {
      from: from,
      to: to,
      subject: subject,
      html: html
    }

    response = Resend::Emails.send(params)

    if Rails.env.development?
      Rails.logger.info "=== RESEND EMAIL SENT ==="
      Rails.logger.info "To: #{to}"
      Rails.logger.info "Subject: #{subject}"
      Rails.logger.info "Response: #{response}"
      Rails.logger.info "========================="
    end

    Rails.logger.info "Resend email sent successfully to #{to}" if Rails.env.production?

    true
  rescue StandardError => e
    Rails.logger.error "Resend API call failed: #{e.message}"
    raise
  end
end
