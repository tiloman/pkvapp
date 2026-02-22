#!/bin/sh
# Asset precompile for Docker build. Sets a dummy secret so the linter
# does not see SECRET_KEY_BASE in the Dockerfile.
export RAILS_ENV=production
export SECRET_KEY_BASE=precompile-dummy
bundle exec rake assets:precompile
