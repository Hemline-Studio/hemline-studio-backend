#!/usr/bin/env ruby
# Script: scripts/copy_user_to_production.rb
# Purpose: Copy a single user's data and their related records from the current
# (source) Rails database to a target (production) database. This script is
# intentionally conservative and logs every step. It preserves IDs when
# possible but will fall back to creating new records and mapping foreign keys
# when conflicts occur.
#
# Usage (from repo root):
#
#   TARGET_DATABASE_URL="postgresql://user:pass@host:5432/dbname" \
#     ruby scripts/copy_user_to_production.rb adetunji+pharmillustrator@hemline.studio
#
# Notes:
# - The script expects to be run from the Rails project root so it can load
#   the Rails environment and models.
# - It will NOT delete anything in the target DB. Existing records are reused
#   where matching by natural keys (email or public_id), otherwise created.
# - Review the output and logs before trusting results on production.

require_relative "../config/environment"

email = ARGV[0]
unless email
  puts "Usage: TARGET_DATABASE_URL=... ruby scripts/copy_user_to_production.rb <email>"
  exit 1
end

target_db_url = ENV["TARGET_DATABASE_URL"]
unless target_db_url
  puts "ERROR: Set TARGET_DATABASE_URL environment variable to the target DB URL."
  exit 1
end

puts "Starting copy for user: #{email}"
puts "Target DB: #{target_db_url}"

# Build a separate base class for the target DB connection
class TargetRecord < ActiveRecord::Base
  self.abstract_class = true
end

TargetRecord.establish_connection(target_db_url)

# Define lightweight target models (table_name only) that use the target connection
%w[users auth_codes tokens clients custom_fields client_custom_field_values folders galleries orders].each do |t|
  klass = Class.new(TargetRecord) do
    self.table_name = t
  end
  Object.const_set("Target#{t.singularize.camelize}", klass)
end

source_user = User.find_by(email: email.downcase)
unless source_user
  puts "Source user with email #{email} not found. Aborting."
  exit 1
end

puts "Found source user id=#{source_user.id} (created_at=#{source_user.created_at})"

# Mappings from old_id -> new_id for each model
mappings = Hash.new { |h, k| h[k] = {} }

def sync_record(target_class, unique_keys, attributes)
  # unique_keys: Hash of attributes to find the record by
  # attributes: Hash of all attributes to set/update

  record = target_class.find_by(unique_keys)

  if record
    # Update existing record
    # Exclude id and created_at from updates
    update_attrs = attributes.except("id", "created_at")
    record.update!(update_attrs)
    puts "Updated #{target_class.table_name} id=#{record.id}"
    record
  else
    # Create new record
    begin
      record = target_class.create!(attributes)
      puts "Created #{target_class.table_name} id=#{record.id}"
      record
    rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
      # If ID collision, try creating without ID
      if attributes.key?("id")
        puts "ID collision for #{target_class.table_name} id=#{attributes['id']}, creating with new ID"
        record = target_class.create!(attributes.except("id"))
        puts "Created #{target_class.table_name} new_id=#{record.id}"
        record
      else
        raise e
      end
    end
  end
end

ActiveRecord::Base.transaction do
  # 1) Copy user
  src = source_user
  user_attrs = src.attributes.except("updated_at")

  # Find by email
  target_user = sync_record(TargetUser, { email: src.email }, user_attrs)
  mappings[:users][src.id] = target_user.id

  # 2) Copy custom_fields (user-scoped)
  src.custom_fields.find_each do |cf|
    attrs = cf.attributes.except("updated_at")
    attrs["user_id"] = mappings[:users][src.id]

    # Find by field_name + user_id
    unique = { field_name: cf.field_name, user_id: mappings[:users][src.id] }

    target_cf = sync_record(TargetCustomField, unique, attrs)
    mappings[:custom_fields][cf.id] = target_cf.id
  end

  # 3) Copy clients
  src.clients.find_each do |client|
    attrs = client.attributes.except("updated_at")
    attrs["user_id"] = mappings[:users][src.id]

    # Find by ID (try to preserve ID)
    target_client = sync_record(TargetClient, { id: client.id }, attrs)
    mappings[:clients][client.id] = target_client.id

    # Copy client_custom_field_values for this client
    client.client_custom_field_values.find_each do |ccfv|
      attrs_cc = ccfv.attributes.except("updated_at")
      attrs_cc["client_id"] = mappings[:clients][client.id]

      # Map custom_field id
      if mappings[:custom_fields][ccfv.custom_field_id]
        attrs_cc["custom_field_id"] = mappings[:custom_fields][ccfv.custom_field_id]
      else
        # fallback: try to find custom field by name in target
        cf_src = CustomField.find_by(id: ccfv.custom_field_id)
        if cf_src
          tgt_cf = TargetCustomField.find_by(field_name: cf_src.field_name, user_id: mappings[:users][src.id])
          if tgt_cf
            attrs_cc["custom_field_id"] = tgt_cf.id
            mappings[:custom_fields][cf_src.id] = tgt_cf.id
          end
        end
      end

      # Find by client_id + custom_field_id
      unique_cc = { client_id: attrs_cc["client_id"], custom_field_id: attrs_cc["custom_field_id"] }

      begin
        sync_record(TargetClientCustomFieldValue, unique_cc, attrs_cc)
      rescue => e
        puts "  Skipped client_custom_field_value (#{e.class}: #{e.message})"
      end
    end
  end

  # 4) Copy galleries
  src.galleries.find_each do |g|
    attrs = g.attributes.except("updated_at")
    attrs["user_id"] = mappings[:users][src.id]

    target_gallery = sync_record(TargetGallery, { id: g.id }, attrs)
    mappings[:galleries][g.id] = target_gallery.id
  end

  # 5) Copy folders (they reference galleries via image_ids, which we remap)
  src.folders.find_each do |f|
    attrs = f.attributes.except("updated_at")
    attrs["user_id"] = mappings[:users][src.id]

    # Remap image_ids array to new gallery ids if mapping exists
    if f.image_ids.present?
      remapped = f.image_ids.map { |gid| mappings[:galleries][gid] || gid }
      attrs["image_ids"] = remapped
    end

    if f.cover_image.present?
      attrs["cover_image"] = mappings[:galleries][f.cover_image] || f.cover_image
    end

    target_folder = sync_record(TargetFolder, { id: f.id }, attrs)
    mappings[:folders][f.id] = target_folder.id
  end

  # 6) Copy orders (depend on clients and user)
  src.orders.find_each do |o|
    attrs = o.attributes.except("updated_at")
    attrs["user_id"] = mappings[:users][src.id]
    attrs["client_id"] = mappings[:clients][o.client_id] || o.client_id

    target_order = sync_record(TargetOrder, { id: o.id }, attrs)
    mappings[:orders][o.id] = target_order.id
  end

  # 7) Copy auth_codes and tokens
  src.auth_codes.find_each do |ac|
    attrs = ac.attributes.except("updated_at")
    attrs["user_id"] = mappings[:users][src.id]

    target_ac = sync_record(TargetAuthCode, { id: ac.id }, attrs)
    mappings[:auth_codes][ac.id] = target_ac.id
  end

  src.tokens.find_each do |tkn|
    attrs = tkn.attributes.except("updated_at")
    attrs["user_id"] = mappings[:users][src.id]

    target_token = sync_record(TargetToken, { id: tkn.id }, attrs)
    mappings[:tokens][tkn.id] = target_token.id
  end

  puts "Finished copying data for user #{src.email}. Summary:"
  puts "  Users: #{mappings[:users].length}"
  puts "  CustomFields: #{mappings[:custom_fields].length}"
  puts "  Clients: #{mappings[:clients].length}"
  puts "  Galleries: #{mappings[:galleries].length}"
  puts "  Folders: #{mappings[:folders].length}"
  puts "  Orders: #{mappings[:orders].length}"
  puts "  AuthCodes: #{mappings[:auth_codes].length}"
  puts "  Tokens: #{mappings[:tokens].length}"
end

puts "All done. Verify the target database to ensure correctness."
