FROM ruby:2.7.2-slim

ENV RAILS_ENV=test
ENV RAILS_LOG_TO_STDOUT=true
ENV SECRET_KEY_BASE=whateverdoesntmatter

RUN apt-get update && apt-get install -y \
  build-essential \
  libmagic-dev \
  libpq-dev \
  curl \
  git \
  shared-mime-info

RUN mkdir app
WORKDIR app

# Copy the main application, except whatever is listed in .dockerignore.
COPY . ./

RUN cp config/credentials/ci.yml config/credentials/test.yml

RUN gem install bundler \
    && bundle config path vendor/bundle \
    && bundle config set without 'development production' \
    && bundle install --jobs 4 --retry 5
