class OrderSerializer
  include JSONAPI::Serializer

  attributes :item, :quantity, :notes, :is_done, :due_date, :created_at, :updated_at

  attribute :client_name do |order|
    order.client.full_name
  end

  attribute :client_id do |order|
    order.client_id
  end

  attribute :overdue do |order|
    order.overdue?
  end
end
