# frozen_string_literal: true

class SyncService
  def self.apply_sync(user:, sync_params:)
    errors = []

    # Clients
    if sync_params[:clients].present?
      errs = apply_clients_sync(user, sync_params[:clients])
      errors.concat(errs)
    end

    # Orders (depends on clients - process after clients)
    if sync_params[:orders].present?
      errs = apply_orders_sync(user, sync_params[:orders])
      errors.concat(errs)
    end

    # Custom fields (delta - only new and updated)
    if sync_params[:custom_fields].present?
      errs = apply_custom_fields_sync(user, sync_params[:custom_fields])
      errors.concat(errs)
    end

    # User profile
    if sync_params[:user_profile].present?
      errs = apply_user_profile_sync(user, sync_params[:user_profile])
      errors.concat(errs)
    end

    { success: errors.empty?, errors: errors }
  end

  def self.apply_clients_sync(user, block)
    errors = []
    block = block.to_unsafe_h if block.respond_to?(:to_unsafe_h)

    # Process creates
    (block["created"] || block[:created] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      attrs = client_attrs_from_sync(item)
      custom_fields_data = item["custom_fields"] || item[:custom_fields]
      custom_fields_data = custom_fields_data.to_unsafe_h if custom_fields_data.respond_to?(:to_unsafe_h)

      client = user.clients.find_by(id: attrs[:id])
      if client.nil?
        client = user.clients.build(attrs)
        if client.save
          save_client_custom_fields(client, custom_fields_data) if custom_fields_data.present?
        else
          errors << "Client #{attrs[:id]}: #{client.errors.full_messages.join(', ')}"
        end
      end
    end

    # Process updates (last-write-wins)
    (block["updated"] || block[:updated] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      client = user.clients.find_by(id: item["id"] || item[:id])
      next unless client

      client_updated = parse_time(item["updated_at"] || item[:updated_at])
      next if client_updated.nil?
      next if client.updated_at >= client_updated # Server has newer data

      attrs = client_attrs_from_sync(item)
      attrs.delete(:id)
      if client.update(attrs)
        update_custom_fields = item["custom_fields"] || item[:custom_fields]
        update_custom_fields = update_custom_fields.to_unsafe_h if update_custom_fields.respond_to?(:to_unsafe_h)
        save_client_custom_fields(client, update_custom_fields) if update_custom_fields.present?
      else
        errors << "Client #{client.id}: #{client.errors.full_messages.join(', ')}"
      end
    end

    # Process deletes (soft delete - in_trash)
    (block["deleted"] || block[:deleted] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      client = user.clients.find_by(id: item["id"] || item[:id])
      next unless client

      deleted_updated = parse_time(item["updated_at"] || item[:updated_at])
      next if deleted_updated.nil?
      next if client.updated_at >= deleted_updated

      client.update!(in_trash: true)
    end

    errors
  end

  def self.apply_orders_sync(user, block)
    errors = []
    block = block.to_unsafe_h if block.respond_to?(:to_unsafe_h)

    (block["created"] || block[:created] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      attrs = order_attrs_from_sync(item)
      order = user.orders.find_by(id: attrs[:id])
      if order.nil?
        # Ensure client belongs to user
        unless user.clients.exists?(id: attrs[:client_id])
          errors << "Order #{attrs[:id]}: Client not found"
          next
        end
        order = user.orders.build(attrs)
        unless order.save
          errors << "Order #{attrs[:id]}: #{order.errors.full_messages.join(', ')}"
        end
      end
    end

    (block["updated"] || block[:updated] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      order = user.orders.find_by(id: item["id"] || item[:id])
      next unless order

      item_updated = parse_time(item["updated_at"] || item[:updated_at])
      next if item_updated.nil?
      next if order.updated_at >= item_updated

      attrs = order_attrs_from_sync(item)
      attrs.delete(:id)
      unless order.update(attrs)
        errors << "Order #{order.id}: #{order.errors.full_messages.join(', ')}"
      end
    end

    (block["deleted"] || block[:deleted] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      order = user.orders.find_by(id: item["id"] || item[:id])
      next unless order

      deleted_updated = parse_time(item["updated_at"] || item[:updated_at])
      next if deleted_updated.nil?
      next if order.updated_at >= deleted_updated

      order.destroy
    end

    errors
  end

  def self.apply_custom_fields_sync(user, block)
    errors = []
    block = block.to_unsafe_h if block.respond_to?(:to_unsafe_h)

    (block["created"] || block[:created] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      field = user.custom_fields.find_by(id: item["id"] || item[:id])
      if field.nil?
        field = user.custom_fields.build(
          id: item["id"] || item[:id],
          field_name: item["field_name"] || item[:field_name],
          field_type: item["field_type"] || item[:field_type] || "measurement",
          is_active: item["is_active"].nil? ? true : item["is_active"]
        )
        unless field.save
          errors << "CustomField #{field.id}: #{field.errors.full_messages.join(', ')}"
        end
      end
    end

    (block["updated"] || block[:updated] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      field = user.custom_fields.find_by(id: item["id"] || item[:id])
      next unless field

      item_updated = parse_time(item["updated_at"] || item[:updated_at])
      next if item_updated.nil?
      next if field.updated_at >= item_updated

      unless field.update(
        field_name: item["field_name"] || item[:field_name],
        field_type: item["field_type"] || item[:field_type],
        is_active: item["is_active"].nil? ? field.is_active : item["is_active"]
      )
        errors << "CustomField #{field.id}: #{field.errors.full_messages.join(', ')}"
      end
    end

    (block["deleted"] || block[:deleted] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?

      field = user.custom_fields.find_by(id: item["id"] || item[:id])
      next unless field

      deleted_updated = parse_time(item["updated_at"] || item[:updated_at])
      next if deleted_updated.nil?
      next if field.updated_at >= deleted_updated

      field.update!(is_active: false)
    end

    errors
  end

  def self.apply_user_profile_sync(user, block)
    errors = []
    block = block.to_unsafe_h if block.respond_to?(:to_unsafe_h)

    (block["updated"] || block[:updated] || []).each do |item|
      item = item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next if item.blank?
      next unless (item["id"] || item[:id]) == user.id.to_s

      item_updated = parse_time(item["updated_at"] || item[:updated_at])
      next if item_updated.nil?
      next if user.updated_at >= item_updated

      attrs = {}
      attrs[:first_name] = item["first_name"] || item[:first_name] if item["first_name"].present? || item[:first_name].present?
      attrs[:last_name] = item["last_name"] || item[:last_name] if item["last_name"].present? || item[:last_name].present?
      attrs[:business_name] = item["business_name"] || item[:business_name] if item.key?("business_name") || item.key?(:business_name)
      attrs[:business_address] = item["business_address"] || item[:business_address] if item.key?("business_address") || item.key?(:business_address)
      next if attrs.empty?

      unless user.update(attrs)
        errors << "User profile: #{user.errors.full_messages.join(', ')}"
      end
    end

    errors
  end

  def self.client_attrs_from_sync(item)
    id = item["id"] || item[:id]
    measurements = item["measurements"] || item[:measurements] || {}
    measurements = measurements.to_unsafe_h if measurements.respond_to?(:to_unsafe_h)

    attrs = {
      id: id,
      first_name: item["first_name"] || item[:first_name],
      last_name: item["last_name"] || item[:last_name],
      gender: item["gender"] || item[:gender],
      measurement_unit: item["measurement_unit"] || item[:measurement_unit] || "centimeters",
      phone_number: item["phone_number"] || item[:phone_number],
      email: item["email"] || item[:email],
      in_trash: item["in_trash"].nil? ? false : item["in_trash"]
    }

    Client.measurement_fields.each do |field|
      val = measurements[field] || measurements[field.to_s]
      attrs[field.to_sym] = val if val.present?
    end

    attrs
  end

  def self.order_attrs_from_sync(item)
    {
      id: item["id"] || item[:id],
      client_id: item["client_id"] || item[:client_id],
      item: item["item"] || item[:item],
      quantity: (item["quantity"] || item[:quantity] || 1).to_i,
      notes: item["notes"] || item[:notes],
      is_done: item["is_done"].nil? ? false : item["is_done"],
      due_date: item["due_date"].present? ? item["due_date"] : nil
    }
  end

  def self.parse_time(str)
    return nil if str.blank?
    Time.zone.parse(str.to_s)
  rescue ArgumentError
    nil
  end

  def self.save_client_custom_fields(client, custom_fields_data)
    return unless custom_fields_data.is_a?(Hash)

    custom_fields_data.each do |custom_field_id, value|
      next if value.blank?

      custom_field = client.user.custom_fields.active.find_by(id: custom_field_id)
      next unless custom_field

      client.set_custom_field_value(custom_field, value.to_s)
    end
  end
end
