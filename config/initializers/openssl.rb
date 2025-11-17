# Fix SSL/TLS connection issues with external APIs (like Resend)
# This is especially important on macOS with Ruby 3.x

require 'openssl'

# Set minimum TLS version to 1.2 (required by most modern APIs)
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:min_version] = OpenSSL::SSL::TLS1_2_VERSION

# Use system certificate store
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ca_file] = nil
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ca_path] = nil

# Enable verification with system certs
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] = OpenSSL::SSL::VERIFY_PEER

Rails.logger.info "OpenSSL configured: #{OpenSSL::OPENSSL_VERSION}"