# Script to update metadata for all existing gallery images
# Usage: bundle exec rails runner scripts/update_gallery_metadata.rb

puts "Starting metadata update for all gallery images..."
puts "=" * 80

# Find all galleries without metadata (where width or height is nil)
galleries = Gallery.where("width IS NULL OR height IS NULL")
total_count = galleries.count

puts "Found #{total_count} gallery images without metadata"
puts "=" * 80

if total_count == 0
  puts "No images need metadata updates. Exiting..."
  exit 0
end

updated_count = 0
failed_count = 0
skipped_count = 0

galleries.find_each.with_index do |gallery, index|
  begin
    print "\r[#{index + 1}/#{total_count}] Processing: #{gallery.file_name} (#{gallery.public_id})..."

    # Fetch resource details from Cloudinary
    result = Cloudinary::Api.resource(gallery.public_id, exif: true)

    # Extract metadata
    metadata = {
      width: result["width"],
      height: result["height"],
      aperture: result.dig("exif", "ApertureValue"),
      camera_model: result.dig("exif", "Model"),
      shutter_speed: result.dig("exif", "ShutterSpeedValue"),
      iso: result.dig("exif", "ISO")
    }

    # Update gallery with metadata
    if gallery.update(metadata)
      updated_count += 1
      print " ✓ Updated"
    else
      failed_count += 1
      print " ✗ Failed: #{gallery.errors.full_messages.join(', ')}"
    end

  rescue Cloudinary::Api::NotFound => e
    failed_count += 1
    print " ✗ Not found in Cloudinary"
    puts "\n  Image may have been deleted: #{gallery.public_id}"

  rescue StandardError => e
    failed_count += 1
    print " ✗ Error: #{e.message}"
    puts "\n  #{e.class}: #{e.message}"
  end

  # Add newline every 10 items for better readability
  puts "" if (index + 1) % 10 == 0

  # Small delay to avoid rate limiting
  sleep(0.1) if (index + 1) % 50 == 0
end

puts "\n"
puts "=" * 80
puts "Metadata update completed!"
puts "=" * 80
puts "Total images processed: #{total_count}"
puts "Successfully updated: #{updated_count}"
puts "Failed: #{failed_count}"
puts "Skipped: #{skipped_count}"
puts "=" * 80

# Show summary of images with metadata
images_with_metadata = Gallery.where.not(width: nil).count
images_with_exif = Gallery.where.not(camera_model: nil).count

puts "\nDatabase Summary:"
puts "Total gallery images: #{Gallery.count}"
puts "Images with dimensions: #{images_with_metadata}"
puts "Images with camera data: #{images_with_exif}"
puts "=" * 80
