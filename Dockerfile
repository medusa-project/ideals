FROM ruby:2.6.3-slim

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_MAX_THREADS=5
ENV RAILS_SERVE_STATIC_FILES=false

RUN apt-get update && apt-get install -y \
  build-essential \
  libmagic-dev \
  libpq-dev \
  curl \
  git

RUN mkdir app
WORKDIR app

# Copy the Gemfile as well as the Gemfile.lock and install gems.
# This is a separate, earlier step in order to cache dependencies.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler \
    && bundle config set without 'development test' \
    && bundle install --jobs 20 --retry 5

# Copy the main application, except whatever is listed in .dockerignore.
# This includes the /config/credentials/*.key files which are needed to decrypt
# the credentials.
COPY . ./

RUN bin/rails assets:precompile

EXPOSE 3000

# N.B.: --engine=builtin works around an issue with the embedded nginx where
# large POST requests cause HTTP 5xx errors.
# Also see: https://www.phusionpassenger.com/library/config/standalone/optimization/
CMD ["bundle", "exec", "passenger", "start", "-p", "3000", "--engine=builtin", "--max-pool-size=16", "--min-instances=16", "--log-file=/dev/stdout"]
