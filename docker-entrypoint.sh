#!/bin/sh
set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle check || bundle install --binstubs="$BUNDLE_BIN"
npm install yarn -g

# https://github.com/nodejs/node-v0.x-archive/issues/3911#issuecomment-8956154
ln -s /usr/bin/nodejs /usr/bin/node
bundle exec rake assets:precompile --trace

exec bundle exec "$@"
