#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# The Turso database is created in Turso itself (db:create isn't supported by the
# turso adapter); this only applies pending migrations.
bundle exec rails db:migrate
