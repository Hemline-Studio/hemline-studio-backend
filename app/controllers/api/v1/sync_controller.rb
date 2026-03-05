# frozen_string_literal: true

class Api::V1::SyncController < Api::V1::BaseController
  include UserDataConcern

  # GET /api/v1/sync/full
  # Returns all clients, orders, custom_fields, and user profile for offline sync.
  def full
    clients = current_user.clients.includes(client_custom_field_values: :custom_field)
    orders = current_user.orders.includes(:client)
    custom_fields = current_user.custom_fields

    clients_data = clients.map { |c| serialize_client_for_sync(c) }
    orders_data = orders.map { |o| serialize_order_for_sync(o) }
    custom_fields_data = custom_fields.map { |cf| serialize_custom_field_for_sync(cf) }
    user_profile_data = user_data(current_user)

    render_success(
      {
        clients: clients_data,
        orders: orders_data,
        custom_fields: custom_fields_data,
        user_profile: user_profile_data,
      },
      "Full sync data retrieved successfully"
    )
  end

  # POST /api/v1/sync
  def create
    sync_params = params.require(:sync).permit!

    if sync_params.blank?
      return render_success(nil, "No sync data provided")
    end

    result = SyncService.apply_sync(user: current_user, sync_params: sync_params)

    if result[:success]
      render_success(nil, "Sync completed successfully")
    else
      render_error(
        result[:errors],
        "Sync completed with errors",
        :unprocessable_content
      )
    end
  rescue StandardError => e
    Rails.logger.error("Sync error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render_error([e.message], "Sync failed", :internal_server_error)
  end

  private

  def serialize_client_for_sync(client)
    measurements = {}
    Client.measurement_fields.each do |field|
      val = client.send(field)
      measurements[field.to_s] = val if val.present?
    end

    custom_fields_hash = {}
    client.client_custom_field_values.includes(:custom_field).each do |ccfv|
      custom_fields_hash[ccfv.custom_field_id] = ccfv.value
    end

    {
      id: client.id,
      first_name: client.first_name,
      last_name: client.last_name,
      gender: client.gender,
      measurement_unit: client.measurement_unit,
      phone_number: client.phone_number,
      email: client.email,
      in_trash: client.in_trash,
      measurements: measurements,
      custom_fields: custom_fields_hash,
      created_at: client.created_at.iso8601,
      updated_at: client.updated_at.iso8601,
    }
  end

  def serialize_order_for_sync(order)
    {
      id: order.id,
      client_id: order.client_id,
      item: order.item,
      quantity: order.quantity,
      notes: order.notes,
      is_done: order.is_done,
      due_date: order.due_date&.iso8601,
      created_at: order.created_at.iso8601,
      updated_at: order.updated_at.iso8601,
    }
  end

  def serialize_custom_field_for_sync(custom_field)
    {
      id: custom_field.id,
      field_name: custom_field.field_name,
      field_type: custom_field.field_type,
      is_active: custom_field.is_active,
      created_at: custom_field.created_at.iso8601,
      updated_at: custom_field.updated_at.iso8601,
    }
  end
end
