class Api::V1::ClientsController < Api::V1::BaseController
  before_action :set_client, only: [ :show, :update ]

  # GET /api/v1/clients
  def index
    clients = current_user.clients.includes(:custom_fields)

    include_trashed = params[:include_trashed]

    if include_trashed.present?
      include_trashed = ActiveModel::Type::Boolean.new.cast(include_trashed)
      clients = include_trashed ? clients.active : clients.trashed
    end

    # Apply search filter if search param is provided
    if params[:search].present?
      search_term = "%#{params[:search].strip.downcase}%"
      clients = clients.where(
        "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ? OR LOWER(phone_number) LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    # Apply sorting based on sort_by parameter
    clients = case params[:sort_by]
    when "last_updated"
      clients.order(updated_at: :desc)
    when "z-a"
      clients.order("LOWER(first_name) DESC, LOWER(last_name) DESC")
    else # default to "a-z"
      clients.order("LOWER(first_name) ASC, LOWER(last_name) ASC")
    end

    result = paginate_collection(clients, params[:per_page])

    serialized_clients = ClientSerializer.new(result[:data]).serializable_hash

    render json: {
      message: "All Clients Retrieved Successfully",
      data: serialized_clients[:data],
      pagination: result[:pagination]
    }, status: :ok
  end

  # GET /api/v1/clients/:id
  def show
    serialized_client = ClientSerializer.new(@client).serializable_hash
    render_success(serialized_client)
  end

  # POST /api/v1/clients
  def create
    # Extract and separate data
    permitted_params = client_params.except(:measurements)
    measurements_data = extract_measurements_params

    @client = current_user.clients.build(permitted_params)

    # Assign measurements to client
    assign_measurements_to_client(@client, measurements_data)

    # Extract custom fields
    custom_fields_data = extract_custom_fields_params

    # Extract orders
    orders_data = extract_orders_params

    ActiveRecord::Base.transaction do
      unless @client.save
        render_validation_errors(@client)
        raise ActiveRecord::Rollback
      end

      # Save custom fields
      save_custom_fields(@client, custom_fields_data) if custom_fields_data.any?

      # Create orders
      if orders_data.any?
        orders_errors = create_orders_for_client(@client, orders_data)
        if orders_errors.any?
          render_error(orders_errors, "Client created but some orders failed", :unprocessable_content)
          raise ActiveRecord::Rollback
        end
      end

      serialized_client = ClientSerializer.new(@client.reload).serializable_hash[:data]
      render_success(serialized_client, "Client created successfully", :created)
    end
  end

  # PATCH /api/v1/clients/:id
  def update
    # Extract and separate data
    permitted_params = client_params.except(:measurements)
    measurements_data = extract_measurements_params

    # Assign measurements to client
    assign_measurements_to_client(@client, measurements_data) if measurements_data.any?

    if @client.update(permitted_params)
      # Extract custom fields safely - same as create method
      custom_fields_data = extract_custom_fields_params

      # Handle custom fields using the same method as create
      save_custom_fields(@client, custom_fields_data) if custom_fields_data.any?

      serialized_client = ClientSerializer.new(@client.reload).serializable_hash[:data]
      render_success(serialized_client, "Client updated successfully")
    else
      render_validation_errors(@client)
    end
  end

  # DELETE /api/v1/clients/bulk_delete
  def bulk_delete
    client_ids = params[:client_ids]

    if client_ids.blank? || !client_ids.is_a?(Array)
      render_error([ "Client IDs must be provided as an array" ], "Invalid parameters", :bad_request)
      return
    end

    # Validate UUIDs
    invalid_ids = client_ids.reject { |id| valid_uuid?(id) }
    if invalid_ids.any?
      render_error([ "Invalid UUID format for IDs: #{invalid_ids.join(', ')}" ], "Invalid parameters", :bad_request)
      return
    end

    begin
      # Only allow bulk delete of current user's clients
      user_clients = current_user.clients.where(id: client_ids)
      affected_count = user_clients.update_all(in_trash: true, updated_at: Time.current)

      render_success(
        { affected_count: affected_count },
        "#{affected_count} client(s) moved to trash successfully"
      )
    rescue StandardError => e
      render_error([ e.message ], "Failed to delete clients", :internal_server_error)
    end
  end

  private

  def set_client
    # Scope client lookup to current user's clients only
    @client = current_user.clients.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("Client not found")
  end

  def client_params
    params.require(:client).permit(
      :first_name, :last_name, :gender, :measurement_unit, :phone_number, :email,
      measurements: [
        :shoulder_width, :bust_chest, :round_underbust, :neck_circumference,
        :armhole_circumference, :arm_length_full, :arm_length_full_three_quarter,
        :sleeve_length, :round_sleeve_bicep, :elbow_circumference, :wrist_circumference,
        :top_length, :bust_point_nipple_to_nipple, :shoulder_to_bust_point,
        :shoulder_to_waist, :round_chest_upper_bust, :back_width, :back_length,
        :tommy_waist, :waist, :high_hip, :hip_full, :lap_thigh, :knee_circumference,
        :calf_circumference, :ankle_circumference, :skirt_length, :trouser_length_outseam,
        :inseam, :crotch_depth, :waist_to_hip, :waist_to_floor, :slit_height,
        :bust_apex_to_waist
      ]
    )
  end

  def handle_custom_fields(client, custom_fields_params)
    return unless custom_fields_params.is_a?(Hash)

    custom_fields_params.each do |custom_field_id, value|
      next if value.blank?

      # Ensure we only work with custom fields that belong to the current user
      custom_field = current_user.custom_fields.active.find_by(id: custom_field_id)
      next unless custom_field

      client.set_custom_field_value(custom_field, value)
    end
  end

  def save_custom_fields(client, custom_fields_params)
    # Check if we got an ActionController::Parameters object
    if custom_fields_params.respond_to?(:to_h)
      custom_fields_params = custom_fields_params.to_h

    end

    return unless custom_fields_params.is_a?(Hash)

    custom_fields_params.each do |custom_field_id, value|
      next if value.blank?

      # Check if the custom field exists for this user
      custom_field = current_user.custom_fields.find_by(id: custom_field_id)

      if custom_field.nil?
        # Let's see what custom fields the user actually has
        next
      end

      unless custom_field.is_active?
        next
      end

      begin
        client.set_custom_field_value(custom_field, value)
      rescue ActiveRecord::RecordInvalid, StandardError
        # Silently continue on error
        next
      end
    end
  end

  # Extract custom fields params
  def extract_custom_fields_params
    return {} unless params[:client] && params[:client][:custom_fields]

    custom_fields_data = params[:client][:custom_fields]

    custom_fields_data = if custom_fields_data.respond_to?(:to_unsafe_h)
      custom_fields_data.to_unsafe_h
    elsif custom_fields_data.respond_to?(:to_h)
      custom_fields_data.to_h
    else
      {}
    end

    custom_fields_data.is_a?(Hash) ? custom_fields_data : {}
  end


  # Extract orders params
  def extract_orders_params
    return [] unless params[:client] && params[:client][:orders]

    orders_data = params[:client][:orders]

    # Ensure it's an array
    orders_data = [ orders_data ] unless orders_data.is_a?(Array)
    orders_data
  end

  # Create orders for a client
  def create_orders_for_client(client, orders_params)
    errors = []

    orders_params.each_with_index do |order_params, index|
      order = client.orders.build(
        order_params.permit(:item, :quantity, :notes, :due_date)
      )
      order.user = current_user

      unless order.save
        errors << "Order #{index + 1}: #{order.errors.full_messages.join(', ')}"
      end
    end

    errors
  end

  def valid_uuid?(string)
    uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
    !!(string =~ uuid_regex)
  end

  # Extract measurements from nested structure
  def extract_measurements_params
    return {} unless params[:client] && params[:client][:measurements]

    measurements_data = params[:client][:measurements]

    measurements_data = if measurements_data.respond_to?(:to_unsafe_h)
      measurements_data.to_unsafe_h
    elsif measurements_data.respond_to?(:to_h)
      measurements_data.to_h
    else
      {}
    end

    measurements_data.is_a?(Hash) ? measurements_data : {}
  end

  # Assign measurements to client from nested structure
  def assign_measurements_to_client(client, measurements_data)
    return unless measurements_data.is_a?(Hash)

    Client.measurement_fields.each do |field|
      value = measurements_data[field] || measurements_data[field.to_sym]
      next unless value

      client.public_send("#{field}=", value)
    end
  end
end
