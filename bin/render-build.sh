#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Create and migrate database
bundle exec rails db:create
bundle exec rails db:migrate

# Setup Solid Queue tables for background jobs
bundle exec rails db:prepare
bundle exec rails solid_queue:install
bundle exec rails db:migrate:queue