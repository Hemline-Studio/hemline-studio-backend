#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Create and migrate database
bundle exec rails db:create
bundle exec rails db:migrate
