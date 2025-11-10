class Api::V1::WaitlistsController < ApplicationController
  # POST /api/v1/waitlist
  def create
    email = params[:email]&.strip&.downcase

    if email.blank?
      render json: {
        success: false,
        message: "Email is required",
        errors: [ "Email is required" ]
      }, status: :bad_request
      return
    end

    waitlist = Waitlist.new(email: email)

    if waitlist.save
      EmailService.send_waitlist_confirmation(waitlist)

      render json: {
        success: true,
        message: "Successfully added to waitlist",
        data: {
          email: waitlist.email,
          joined_at: waitlist.created_at
        }
      }, status: :created

    else
      # Check if it's a duplicate email
      if waitlist.errors[:email].include?("has already been taken")
        render json: {
          success: false,
          message: "You are already on the waitlist"
        }, status: :ok
      else
        render json: {
          success: false,
          message: "Failed to join waitlist",
          errors: waitlist.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
end
