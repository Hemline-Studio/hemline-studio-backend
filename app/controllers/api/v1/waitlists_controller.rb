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
          message: "Email already on waitlist",
          errors: [ "This email is already registered on our waitlist" ]
        }, status: :unprocessable_entity
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
