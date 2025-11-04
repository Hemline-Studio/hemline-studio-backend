class Api::V1::OrdersController < Api::V1::BaseController
  before_action :set_order, only: [ :show, :update, :destroy ]
  before_action :set_client, only: [ :create_for_client ]

  # GET /api/v1/orders
  def index
    orders = current_user.orders.includes(:client)

    # Filter by status
    if params[:status].present?
      case params[:status]
      when "pending"
        orders = orders.pending
      when "completed"
        orders = orders.completed
      when "overdue"
        orders = orders.overdue
      when "upcoming"
        orders = orders.upcoming
      end
    end

    # Filter by client
    orders = orders.where(client_id: params[:client_id]) if params[:client_id].present?

    # Apply search filter if search param is provided
    if params[:search].present?
      search_term = "%#{params[:search].strip.downcase}%"
      orders = orders.joins(:client).where(
        "LOWER(orders.item) LIKE ? OR LOWER(orders.notes) LIKE ? OR LOWER(clients.first_name) LIKE ? OR LOWER(clients.last_name) LIKE ? OR LOWER(clients.email) LIKE ? OR LOWER(clients.phone_number) LIKE ?",
        search_term, search_term, search_term, search_term, search_term, search_term
      )
    end

    # Apply sorting based on sort_by parameter
    orders = case params[:sort_by]
    when "last_updated"
      orders.order(updated_at: :desc)
    when "due_date_asc"
      orders.order(Arel.sql("due_date ASC NULLS LAST"))
    when "due_date_desc"
      orders.order(Arel.sql("due_date DESC NULLS LAST"))
    when "a-z"
      orders.order(Arel.sql("LOWER(orders.item) ASC"))
    when "z-a"
      orders.order(Arel.sql("LOWER(orders.item) DESC"))
    else # default ordering: pending first (ordered by due date), then completed
      orders.ordered_by_due_date
    end

    result = paginate_collection(orders, params[:per_page] || 20)

    # Serialize each order individually to avoid passing an ActiveRecord::Relation
    serialized_orders = result[:data].map { |order| OrderSerializer.new(order).as_json }

    payload = {
      orders: serialized_orders,
      pagination: result[:pagination]
    }

    render_success(payload, "Orders retrieved successfully", :ok)
  end

  # GET /api/v1/orders/:id
  def show
    serialized_order = OrderSerializer.new(@order).as_json
    render_success(serialized_order, "Order retrieved successfully", :ok)
  end

  # POST /api/v1/orders
  def create
    orders_params = params[:orders] || [ params[:order] ]

    unless orders_params.is_a?(Array)
      render_error([ "Orders must be an array" ], "Invalid parameters", :bad_request)
      return
    end

    created_orders = []
    errors = []

    ActiveRecord::Base.transaction do
      orders_params.each_with_index do |order_params, index|
        order = current_user.orders.build(order_params.permit(:client_id, :item, :quantity, :notes, :due_date))

        # Validate client belongs to user
        unless current_user.clients.exists?(id: order.client_id)
          errors << "Order #{index + 1}: Client not found or doesn't belong to you"
          raise ActiveRecord::Rollback
        end

        if order.save
          created_orders << order
        else
          errors << "Order #{index + 1}: #{order.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end
      end
    end

    if errors.any?
      render_error(errors, "Failed to create orders", :unprocessable_entity)
    else
      serialized_orders = created_orders.map { |order| OrderSerializer.new(order).as_json }
      render_success({ orders: serialized_orders }, "#{created_orders.count} order(s) created successfully", :created)
    end
  end

  # POST /api/v1/clients/:client_id/orders
  def create_for_client
    orders_params = params[:orders] || [ params[:order] ]

    unless orders_params.is_a?(Array)
      render_error([ "Orders must be an array" ], "Invalid parameters", :bad_request)
      return
    end

    created_orders = []
    errors = []

    ActiveRecord::Base.transaction do
      orders_params.each_with_index do |order_params, index|
        order = @client.orders.build(order_params.permit(:item, :quantity, :notes, :due_date))
        order.user = current_user

        if order.save
          created_orders << order
        else
          errors << "Order #{index + 1}: #{order.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end
      end
    end

    if errors.any?
      render_error(errors, "Failed to create orders", :unprocessable_entity)
    else
      serialized_orders = created_orders.map { |order| OrderSerializer.new(order).as_json }
      render_success({ orders: serialized_orders }, "#{created_orders.count} order(s) created successfully", :created)
    end
  end

  # PATCH /api/v1/orders/:id
  def update
    if @order.update(order_params)
      serialized_order = OrderSerializer.new(@order.reload).as_json
      render_success(serialized_order, "Order updated successfully")
    else
      render_validation_errors(@order)
    end
  end

  # PATCH /api/v1/orders/:id/mark_done
  def mark_done
    set_order
    if @order.mark_done!
      serialized_order = OrderSerializer.new(@order).as_json
      render_success(serialized_order, "Order marked as done")
    else
      render_validation_errors(@order)
    end
  end

  # PATCH /api/v1/orders/:id/mark_pending
  def mark_pending
    set_order
    if @order.mark_pending!
      serialized_order = OrderSerializer.new(@order).as_json
      render_success(serialized_order, "Order marked as pending")
    else
      render_validation_errors(@order)
    end
  end

  # DELETE /api/v1/orders/bulk_delete
  def bulk_delete
    order_ids = params[:order_ids]

    if order_ids.blank? || !order_ids.is_a?(Array)
      render_error([ "Order IDs must be provided as an array" ], "Invalid parameters", :bad_request)
      return
    end

    # Validate UUIDs
    invalid_ids = order_ids.reject { |id| valid_uuid?(id) }
    if invalid_ids.any?
      render_error([ "Invalid UUID format for IDs: #{invalid_ids.join(', ')}" ], "Invalid parameters", :bad_request)
      return
    end

    begin
      user_orders = current_user.orders.where(id: order_ids)
      affected_count = user_orders.count
      user_orders.destroy_all

      render_success(
        { affected_count: affected_count },
        "#{affected_count} order(s) deleted successfully"
      )
    rescue StandardError => e
      render_error([ e.message ], "Failed to delete orders", :internal_server_error)
    end
  end

  # DELETE /api/v1/orders/:id
  def destroy
    @order.destroy
    render_success(nil, "Order deleted successfully")
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("Order not found")
  end

  def set_client
    @client = current_user.clients.find(params[:client_id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("Client not found")
  end

  def order_params
    params.require(:order).permit(:client_id, :item, :quantity, :notes, :due_date, :is_done)
  end

  def valid_uuid?(string)
    uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
    !!(string =~ uuid_regex)
  end
end
