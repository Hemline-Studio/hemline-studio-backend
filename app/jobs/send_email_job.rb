class SendEmailJob < ApplicationJob
  queue_as :default

  # Retry up to 3 times with exponential backoff
  # retry_on StandardError, wai, attempts: 3

  def perform(email_type, *args)
    # Determine which email service to use
    email_service = Rails.env.production? ? ResendEmailService : EmailService

    case email_type
    when "magic_link"
      user_id, auth_code_id = args
      user = User.find(user_id)
      auth_code = AuthCode.find(auth_code_id)

      result = email_service.send_magic_link(user, auth_code)
      Rails.logger.info "Successfully sent #{email_type} email"
      unless result[:success]
        Rails.logger.error "Failed to send magic link email: #{result[:message]}"
        raise StandardError, result[:message]
      end

    when "welcome_email"
      user_id = args.first
      user = User.find(user_id)

      result = email_service.send_welcome_email(user)

      unless result[:success]
        Rails.logger.error "Failed to send welcome email: #{result[:message]}"
        raise StandardError, result[:message]
      end

    when "folder_share"
      options = args.first
      folder = Folder.find(options[:folder_id])
      user = User.find(options[:user_id])

      result = email_service.send_folder_share_email(
        to: options[:to],
        folder: folder,
        user: user,
        recipient_name: options[:recipient_name],
        base_url: options[:base_url]
      )

      unless result[:success]
        Rails.logger.error "Failed to send folder share email: #{result[:message]}"
        raise StandardError, result[:message]
      end

    else
      raise ArgumentError, "Unknown email type: #{email_type}"
    end

    Rails.logger.info "Successfully sent #{email_type} email"
  end
end
