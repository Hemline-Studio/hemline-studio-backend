class ClientSerializer
  include JSONAPI::Serializer

  attributes :id, :first_name, :last_name, :gender, :measurement_unit, :phone_number, :email, :in_trash, :created_at, :updated_at

  # Full name convenience attribute
  attribute :full_name do |client|
    client.full_name
  end

  # Include all new measurements, converted to display format
  Client.measurement_fields.each do |measurement|
    attribute measurement.to_sym do |client|
      value = client.send(measurement)
      next unless value

      client.measurement_unit == "inches" ? (value / 2.54).round(2) : value.to_f
    end
  end

  # Custom field values
  attribute :custom_fields do |client|
    client.client_custom_field_values.includes(:custom_field).map do |ccfv|
      {
        id: ccfv.custom_field.id,
        field_name: ccfv.custom_field.field_name,
        field_type: ccfv.custom_field.field_type,
        value: ccfv.value
      }
    end
  end

  # Orders
  attribute :orders do |client|
    client.orders.map do |order|
      {
        id: order.id,
        item: order.item,
        quantity: order.quantity,
        notes: order.notes,
        is_done: order.is_done,
        due_date: order.due_date,
        overdue: order.overdue?,
        created_at: order.created_at,
        updated_at: order.updated_at
      }
    end
  end

  # Order counts
  attribute :total_orders do |client|
    client.orders.count
  end

  attribute :pending_orders_count do |client|
    client.orders.pending.count
  end

  attribute :completed_orders_count do |client|
    client.orders.completed.count
  end
end
