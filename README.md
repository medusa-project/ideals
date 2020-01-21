# IDEALS

This is the Ruby on Rails web application component of IDEALS, the Illinois
Digital Environment for Access to Learning and Scholarship, which publishes
research and scholarship from the University of Illinois at Urbana-Champaign.

This is a getting-started guide for developers.

# Quick Links

* [JIRA Project](https://bugs.library.illinois.edu/projects/IR)

# Requirements

* PostgreSQL >= 9.x
* Elasticsearch >= 7.x

# Installation

## Install everything
```sh
# Install rbenv
$ brew install rbenv
$ brew install ruby-build
$ brew install rbenv-gemset --HEAD
$ rbenv init
$ rbenv rehash

# Clone the repository
$ git clone https://github.com/medusa-project/ideals.git
$ cd ideals

# Install Ruby into rbenv
$ rbenv install "$(< .ruby-version)"

# Install Bundler
$ gem install bundler

# Install application gems
$ bundle install
```

## Configure the application

```sh
$ cd config/credentials
$ cp template.yml development.yml
$ cp template.yml test.yml
```
Edit both as necessary.

## Create the Elasticsearch indexes

```sh
rails "elasticsearch:indexes:create[ideals_development]"
rails "elasticsearch:indexes:create[ideals_test]"
```
Note: the index schema may change from time to time. Index schemas can't
generally be changed in place, so a new index has to be created with the new
schema, and then existing documents migrated into it. For the development index,
instead of the above, you may prefer to have separate "blue" and "green"
indexes and to switch back-and-forth between them as needed, like:
```sh
rails "elasticsearch:indexes:create[ideals_blue_development]"
rails "elasticsearch:indexes:create_alias[ideals_blue_development,ideals_development]"
```
Then when you need to create a new index, you switch to the "green" one:
```sh
rails "elasticsearch:indexes:create[ideals_green_development]"
rails "elasticsearch:indexes:copy[ideals_blue_development,ideals_green_development]"
rails "elasticsearch:indexes:delete_alias[ideals_blue_development,ideals_development]"
rails "elasticsearch:indexes:create_alias[ideals_green_development,ideals_development]"
rails "elasticsearch:indexes:delete[ideals_blue_development]"
```
(Instead of using aliases, you could change the `elasticsearch/index` key in
your `development.yml` config file. Your choice.)

Note 2: the above does not apply to the test index. This index will be
recreated automatically when the tests are run.

## Create and seed the databases

```
$ rails db:create
$ rails db:create -e test
$ rails db:seed
```

## Add a user for yourself

```
$ rails "ideals:users:create[my_username,my_password]"
```

## Run

```
$ rails server
```

# Configuration System

See the class documentation in `app/config/configuration.rb` for a detailed
explanation of how the configurarion system works. TLDR:

* development
    1. Copy `config/credentials/template.yml` to
      `config/credentials/development.yml`
    2. Edit that
* test
    1. Copy `config/credentials/template.yml` to `config/credentials/test.yml`
    2. Edit that
* demo
    1. Obtain `config/credentials/demo.key`
    2. `rails credentials:edit -e demo`
* production
    1. Obtain `config/credentials/production.key`
    2. `rails credentials:edit -e production`
