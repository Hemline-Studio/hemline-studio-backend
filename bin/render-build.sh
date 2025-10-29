#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Prepare database (creates if needed, runs migrations, loads schema)
# This handles all database setup including solid_queue tables
bundle exec rails db:prepare