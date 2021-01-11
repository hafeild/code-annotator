#!/bin/sh

bundle exec rake db:setup RAILS_ENV=production

bundle exec rake db:migrate RAILS_ENV=production &&
    unicorn_rails -p 5000 -o 0.0.0.0 -E production