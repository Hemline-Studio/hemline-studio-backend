# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a default user for seeding
user = User.find_or_create_by!(email: 'adetunjiadeyinka29@gmail.com') do |u|
  u.first_name = 'Demo'
  u.last_name = 'User'
end

puts "Created or found user: #{user.email}"

# # Create some sample custom fields
# custom_fields = [
#   { field_name: 'Collar Width', field_type: 'measurement' },
#   { field_name: 'Cuff Length', field_type: 'measurement' },
#   { field_name: 'Trouser Rise', field_type: 'measurement' },
#   { field_name: 'Jacket Vents', field_type: 'text' },
#   { field_name: 'Fabric Preference', field_type: 'text' }
# ]

# custom_fields.each do |field_attrs|
#   CustomField.find_or_create_by!(field_name: field_attrs[:field_name]) do |field|
#     field.field_type = field_attrs[:field_type]
#     field.is_active = true
#   end
# end

# puts "Created #{CustomField.count} custom fields"

# # Create some sample clients
# clients_data = [
#   {
#     name: 'John Doe',
#     gender: 'Male',
#     measurement_unit: 'inches',
#     email: 'john.doe@example.com',
#     phone_number: '+1234567890',
#     chest: 42.0,
#     waist: 32.0,
#     height: 72.0,
#     shoulder: 18.0,
#     sleeve: 25.0
#   },
#   {
#     name: 'Jane Smith',
#     gender: 'Female',
#     measurement_unit: 'centimeters',
#     email: 'jane.smith@example.com',
#     phone_number: '+0987654321',
# #     chest: 95.0,
# #     waist: 75.0,
# #     height: 165.0,
# #     hip: 98.0
# #   },
# #   {
# #     name: 'Robert Johnson',
# #     gender: 'Male',
# #     measurement_unit: 'inches',
# #     email: 'robert.johnson@example.com',
# #     chest: 44.0,
# #     waist: 36.0,
# #     height: 74.0,
# #     shoulder: 19.0,
# #     sleeve: 26.0,
# #     neck: 16.5
# #   }
# # ]

# # clients_data.each do |client_attrs|
# #   client = user.clients.find_or_create_by!(email: client_attrs[:email]) do |c|
# #     client_attrs.each { |key, value| c.send("#{key}=", value) }
# #   end

# #   # Add some custom field values
# #   if client.persisted?
# #     collar_width_field = CustomField.find_by(field_name: 'Collar Width')
# #     fabric_preference_field = CustomField.find_by(field_name: 'Fabric Preference')

# #     if collar_width_field && client.measurement_unit == 'inches'
# #       client.set_custom_field_value(collar_width_field, '15.5')
# #     end

# #     if fabric_preference_field
# #       preferences = [ 'Cotton', 'Wool', 'Linen', 'Silk' ]
# #       client.set_custom_field_value(fabric_preference_field, preferences.sample)
# #     end
# #   end
# # end

# # puts "Created #{Client.count} clients for user #{user.email}"

# # Clear existing gallery images for this user
# puts "Clearing existing gallery images..."
# user.galleries.destroy_all

# # Create sample gallery images with UUID format (auto-generated)
# gallery_data = [
#   {
#     file_name: 'portrait-1.jpg',
#     url: 'https://placehold.co/800x1000/3b82f6/ffffff?text=Portrait+1',
#     public_id: 'tailor_app/portrait_1'
#   },
#   {
#     file_name: 'fabric-sample-1.jpg',
#     url: 'https://placehold.co/600x600/ef4444/ffffff?text=Fabric+Sample',
#     public_id: 'tailor_app/fabric_sample_1'
#   },
#   {
#     file_name: 'garment-front.jpg',
#     url: 'https://placehold.co/800x1200/10b981/ffffff?text=Garment+Front',
#     public_id: 'tailor_app/garment_front'
#   },
#   {
#     file_name: 'garment-back.jpg',
#     url: 'https://placehold.co/800x1200/f59e0b/ffffff?text=Garment+Back',
#     public_id: 'tailor_app/garment_back'
#   },
#   {
#     file_name: 'measurement-guide.jpg',
#     url: 'https://placehold.co/1000x800/8b5cf6/ffffff?text=Measurement+Guide',
#     public_id: 'tailor_app/measurement_guide'
#   },
#   {
#     file_name: 'design-sketch.jpg',
#     url: 'https://placehold.co/600x800/ec4899/ffffff?text=Design+Sketch',
#     public_id: 'tailor_app/design_sketch'
#   },
#   {
#     file_name: 'fabric-texture-1.jpg',
#     url: 'https://placehold.co/800x800/06b6d4/ffffff?text=Fabric+Texture',
#     public_id: 'tailor_app/fabric_texture_1'
#   },
#   {
#     file_name: 'completed-suit.jpg',
#     url: 'https://placehold.co/800x1000/84cc16/ffffff?text=Completed+Suit',
#     public_id: 'tailor_app/completed_suit'
#   },
#   {
#     file_name: 'detail-shot.jpg',
#     url: 'https://placehold.co/600x600/f97316/ffffff?text=Detail+Shot',
#     public_id: 'tailor_app/detail_shot'
#   },
#   {
#     file_name: 'client-photo.jpg',
#     url: 'https://placehold.co/800x800/6366f1/ffffff?text=Client+Photo',
#     public_id: 'tailor_app/client_photo'
#   }
# ]

# gallery_data.each do |image_attrs|
#   Gallery.create!(
#     file_name: image_attrs[:file_name],
#     url: image_attrs[:url],
#     public_id: image_attrs[:public_id],
#     user: user
#   )
# end

# puts "Created #{user.galleries.count} gallery images for user #{user.email}"


# Sample data arrays
first_names_female = %w[Emma Olivia Ava Sophia Isabella Mia Charlotte Amelia Harper Evelyn Abigail Emily Elizabeth Sofia Avery Ella]
first_names_male = %w[Liam Noah Oliver Elijah William James Benjamin Lucas Henry Alexander Mason Michael Ethan Daniel Jacob]
last_names = %w[Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin Lee]

# Fashion items for orders
fashion_items = [
  "Wedding Dress", "Evening Gown", "Cocktail Dress", "Business Suit", "Blazer",
  "Trousers", "Skirt", "Blouse", "Shirt", "Coat", "Jacket", "Jumpsuit",
  "Traditional Attire", "Prom Dress", "Bridesmaid Dress", "Tuxedo", "Waistcoat",
  "Palazzo Pants", "Midi Dress", "Maxi Dress", "A-Line Skirt", "Pencil Skirt"
]

order_notes = [
  "Needs to be ready for special event",
  "Customer prefers silk fabric",
  "Rush order",
  "Customer wants lace details",
  "Add embroidery on collar",
  "Make fitting adjustments",
  "Use imported fabric",
  "Traditional design requested",
  "Modern cut preferred",
  "Vintage style",
  "Casual fit",
  "Formal occasion",
  "Wedding party attire",
  "Corporate event",
  "Anniversary celebration"
]

puts "\nCreating 30 clients..."

clients = []
30.times do |i|
  gender = [ "Male", "Female" ].sample
  first_name = gender == "Female" ? first_names_female.sample : first_names_male.sample
  last_name = last_names.sample

  client = user.clients.create!(
    first_name: first_name,
    last_name: last_name,
    gender: gender,
    email: "#{first_name.downcase}.#{last_name.downcase}@example.com",
    phone_number: "+1#{rand(200..999)}#{rand(100..999)}#{rand(1000..9999)}",
    measurement_unit: [ "inches", "centimeters" ].sample,

    # Random measurements (in centimeters)
    shoulder_width: rand(35.0..45.0).round(1),
    bust_chest: gender == "Female" ? rand(80.0..100.0).round(1) : rand(90.0..110.0).round(1),
    waist: gender == "Female" ? rand(60.0..80.0).round(1) : rand(75.0..95.0).round(1),
    hip_full: gender == "Female" ? rand(85.0..105.0).round(1) : rand(90.0..105.0).round(1),
    neck_circumference: rand(32.0..40.0).round(1),
    sleeve_length: rand(55.0..65.0).round(1),
    arm_length_full: rand(55.0..65.0).round(1),
    arm_length_three_quarter: rand(40.0..50.0).round(1),
    round_sleeve_bicep: rand(25.0..35.0).round(1),
    wrist_circumference: rand(14.0..18.0).round(1),
    elbow_circumference: rand(23.0..28.0).round(1),
    top_length: rand(55.0..75.0).round(1),
    shoulder_to_waist: rand(40.0..50.0).round(1),
    back_width: rand(35.0..42.0).round(1),
    back_length: rand(38.0..46.0).round(1),
    high_hip: rand(80.0..95.0).round(1),
    knee_circumference: rand(35.0..42.0).round(1),
    calf_circumference: rand(32.0..40.0).round(1),
    ankle_circumference: rand(20.0..26.0).round(1),
    trouser_length_outseam: rand(95.0..110.0).round(1),
    inseam: rand(70.0..85.0).round(1),
    crotch_depth: rand(25.0..32.0).round(1),
    skirt_length: rand(50.0..75.0).round(1)
  )

  clients << client
  print "."
end

puts "\n✓ Created #{clients.count} clients"

# Select 15 random clients to have orders
puts "\nCreating orders for 15 random clients..."

clients_with_orders = clients.sample(15)
order_count = 0

clients_with_orders.each do |client|
  # Each client gets 1-4 orders
  num_orders = rand(1..4)

  num_orders.times do
    # Some orders are completed, some pending, some overdue
    order_status = rand(1..10)
    is_done = order_status <= 3 # 30% completed

    # Generate due dates
    if is_done
      # Completed orders have past due dates
      due_date = rand(1..30).days.ago
    else
      # Pending orders - some overdue, some upcoming
      if order_status <= 6 # Some are overdue
        due_date = rand(1..15).days.ago
      else # Some are upcoming
        due_date = rand(1..60).days.from_now
      end
    end

    user.orders.create!(
      client: client,
      item: fashion_items.sample,
      quantity: rand(1..3),
      notes: order_notes.sample,
      due_date: due_date,
      is_done: is_done
    )

    order_count += 1
    print "."
  end
end

puts "\n✓ Created #{order_count} orders for #{clients_with_orders.count} clients"

# Print summary
puts "\n" + "="*50
puts "SEED DATA SUMMARY"
puts "="*50
puts "User: #{user.email}"
puts "Total Clients: #{Client.count}"
puts "  - Male: #{Client.male.count}"
puts "  - Female: #{Client.female.count}"
puts "Total Orders: #{Order.count}"
puts "  - Pending: #{Order.pending.count}"
puts "  - Completed: #{Order.completed.count}"
puts "  - Overdue: #{Order.overdue.count}"
puts "  - Upcoming: #{Order.upcoming.count}"
puts "Clients with orders: #{Client.joins(:orders).distinct.count}"
puts "Clients without orders: #{Client.left_joins(:orders).where(orders: { id: nil }).count}"
puts "="*50

puts "\n✅ Seeding completed successfully!"
puts "\nTest credentials:"
puts "  Email: test@example.com"
puts "  You can use this account to test the API"
