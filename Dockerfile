# syntax = docker/dockerfile:1

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t my-app .
# docker run -d -p 80:80 -p 443:443 --name my-app -e RAILS_MASTER_KEY=<value from config/master.key> my-app

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.1.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Ruby 3.1's bundled RubyGems (3.3.7) predates gnu/musl platform gems, so it
# asks rubygems.org for e.g. tailwindcss-ruby-4.3.3-x86_64-linux.gem, which
# doesn't exist (only -gnu/-musl variants do) and 403s. Upgrade it so bundle
# install can fetch those gems.
RUN gem update --system --no-document

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
# The path gem pay-razorback_processor (engines/) must be present when bundler
# resolves it, so copy the engine before bundle install.
COPY engines/ engines/
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for the Rails-rendered pages (propshaft + importmap).
# SECRET_KEY_BASE_DUMMY lets this run without the real secret, which is only
# injected at runtime. APARTMENT_DISABLE_INIT skips Apartment's boot-time
# Tenant.init (its ARGV guard misses this Rails 7.2 invocation), which would
# otherwise connect to a DB that doesn't exist during the build.
RUN SECRET_KEY_BASE_DUMMY=1 APARTMENT_DISABLE_INIT=1 bundle exec rails assets:precompile




# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3001
CMD ["./bin/rails", "server", "-p", "3001"]
