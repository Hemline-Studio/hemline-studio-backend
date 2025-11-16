#!/usr/bin/env ruby

# Test script for Magic Link Authentication API
# This script demonstrates how to use the authentication endpoints

require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'

def make_request(method, path, body = nil)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)

  case method.upcase
  when 'GET'
    request = Net::HTTP::Get.new(uri)
  when 'POST'
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = body.to_json if body
  when 'DELETE'
    request = Net::HTTP::Delete.new(uri)
  end

  response = http.request(request)

  puts "#{method.upcase} #{path}"
  puts "Status: #{response.code}"
  puts "Response: #{JSON.pretty_generate(JSON.parse(response.body))}"
  puts "-" * 50

  JSON.parse(response.body)
rescue => e
  puts "Error: #{e.message}"
  nil
end

def make_authenticated_request(method, path, token, body = nil)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)

  case method.upcase
  when 'GET'
    request = Net::HTTP::Get.new(uri)
  when 'POST'
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = body.to_json if body
  when 'DELETE'
    request = Net::HTTP::Delete.new(uri)
  end

  request['Authorization'] = "Bearer #{token}"

  response = http.request(request)

  puts "#{method.upcase} #{path} (Authenticated)"
  puts "Status: #{response.code}"
  puts "Response: #{JSON.pretty_generate(JSON.parse(response.body))}"
  puts "-" * 50

  JSON.parse(response.body)
rescue => e
  puts "Error: #{e.message}"
  nil
end

puts "=== MAGIC LINK AUTHENTICATION TEST ==="
puts

# Step 1: Request magic link for new user
puts "1. Requesting magic link for new user..."
response = make_request('POST', '/api/v1/auth/request_magic_link', {
  email: 'john.doe@example.com',
  first_name: 'John',
  last_name: 'Doe'
})

if response && response['debug']
  code = response['debug']['code']
  magic_link = response['debug']['magic_link']

  puts "Got debug info:"
  puts "Code: #{code}"
  puts "Magic Link: #{magic_link}"
  puts

  # Step 2: Verify using code
  puts "2. Verifying using 6-digit code..."
  auth_response = make_request('POST', '/api/v1/auth/verify_code', {
    code: code
  })

  if auth_response && auth_response['token']
    token = auth_response['token']
    puts "Authentication successful! Got JWT token."
    puts

    # Step 3: Test authenticated endpoint
    puts "3. Testing authenticated endpoint..."
    make_authenticated_request('GET', '/api/v1/auth/me', token)

    # Step 4: Test logout
    puts "4. Testing logout..."
    make_authenticated_request('DELETE', '/api/v1/auth/logout', token)
  end

  puts
  puts "5. Testing magic link verification..."
  # Extract token from magic link
  magic_token = magic_link.split('token=').last
  magic_auth_response = make_request('GET', "/api/v1/auth/verify?token=#{magic_token}")

  if magic_auth_response && magic_auth_response['token']
    magic_jwt_token = magic_auth_response['token']
    puts "Magic link authentication successful!"
    puts

    # Test authenticated endpoint with magic link token
    puts "6. Testing authenticated endpoint with magic link token..."
    make_authenticated_request('GET', '/api/v1/auth/me', magic_jwt_token)
  end
end

puts
puts "7. Testing existing user login..."
# Request magic link for existing user (should not require first_name/last_name)
existing_response = make_request('POST', '/api/v1/auth/request_magic_link', {
  email: 'john.doe@example.com'
})

puts
puts "=== TEST COMPLETE ==="
