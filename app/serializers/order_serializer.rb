class OrderSerializer
  include JSONAPI::Serializer

  def initialize(order)
    @order = order
  end

  attributes :item, :quantity, :notes, :is_done, :due_date, :created_at, :updated_at

  # attribute :client_name do |order|
  #   order.client.full_name
  # end

  attribute :client_name do |order|
    [ order.client.first_name, order.client.last_name ].compact.join(" ").strip
  end

  attribute :client_id do |order|
    order.client_id
  end

  attribute :overdue do |order|
    order.overdue?
  end

  def as_json
    {
      id: @order.id,
      item: @order.item,
      quantity: @order.quantity,
      notes: @order.notes,
      is_done: @order.is_done,
      due_date: @order.due_date&.iso8601,
      created_at: @order.created_at&.iso8601,
      updated_at: @order.updated_at&.iso8601,
      client_name: [ @order.client&.first_name, @order.client&.last_name ].compact.join(" ").strip,
      client_id: @order.client_id,
      overdue: @order.overdue?
    }
  end


  def to_json(*args)
    as_json.to_json(*args)
  end
end
