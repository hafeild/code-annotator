#!/bin/sh

export RAILS_ENV=production

## This will fail if the database is already setup -- that's okay!
bundle exec rake db:create
bundle exec rake db:schema:load

## Perform any migrations and fire up the server.
bundle exec rake db:migrate &&
    unicorn_rails -p 5000 -o 0.0.0.0 -E production