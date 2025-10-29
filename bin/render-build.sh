#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Create and migrate database
bundle exec rails db:create
bundle exec rails db:migrate

# Load Solid Queue schema to create background job tables
bundle exec rails db:schema:load:queue
bundle exec rails runner "load 'db/queue_schema.rb'"