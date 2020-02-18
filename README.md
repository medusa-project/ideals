# IDEALS

This is the Ruby on Rails web application component of IDEALS, the Illinois
Digital Environment for Access to Learning and Scholarship, which publishes
research and scholarship from the University of Illinois at Urbana-Champaign.

This is a getting-started guide for developers.

# Quick Links

* [JIRA Project](https://bugs.library.illinois.edu/projects/IR)

# Requirements

* PostgreSQL >= 9.x
* Elasticsearch >= 7.x with the
  [ICU analysis plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-icu.html)
  installed

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
schema, and then either existing documents migrated into it, or new documents
loaded into it. For the development index, you may prefer to have separate
"blue" and "green" indexes and to switch back-and-forth between them as needed:

```sh
rails "elasticsearch:indexes:create[ideals_blue_development]"
rails "elasticsearch:indexes:create_alias[ideals_blue_development,ideals_development]"
```
Then when you need to create a new index, you can switch to the "green" one and
delete the blue one:

```sh
rails "elasticsearch:indexes:create[ideals_green_development]"
rails "elasticsearch:indexes:copy[ideals_blue_development,ideals_green_development]"
rails "elasticsearch:indexes:delete_alias[ideals_blue_development,ideals_development]"
rails "elasticsearch:indexes:create_alias[ideals_green_development,ideals_development]"
rails "elasticsearch:indexes:delete[ideals_blue_development]"
```
(Instead of using aliases, you could also change the `elasticsearch/index` key
in your `development.yml`.)

Note 2: the above does not apply to the test index. This index will be
recreated automatically when the tests are run.

## Create and seed the databases

```sh
$ rails db:create
$ rails db:migrate
$ rails db:seed
```

## Add a user for yourself

```sh
$ rails "ideals:users:create[my_username,my_password]"
```

## Migrate content from IDEALS-DSpace into the application

Currently the migration process requires dropping the existing database and
starting over with a new one.

A prerequisite is a dump of the IDEALS-DSpace database loaded into a PostgreSQL
instance and named `dbname`.

### In development

```sh
rails elasticsearch:purge
rails db:reset
rails "ideals_dspace:migrate[dbname,dbhost,dbuser]"
rails "ideals:users:create[username,password]"
rails ideals:seed
rails elasticsearch:reindex[3] # thread count
```
N.B.: (`dbhost` and `dbuser`) are only required if the database is on a
different host and/or the database user is different from the default.

### In demo

```sh
~/bin/stop-rails
rails elasticsearch:purge
rails db:reset
rails "ideals_dspace:migrate[dbname,dbhost,dbuser]"
rails ideals:seed
rails elasticsearch:reindex[2] # thread count
```

## Run the web app

```sh
$ rails server
```

# Branches & Environments

| Rails Environment | Git Branch                 | Machine                | Configuration File                       |
|-------------------|----------------------------|------------------------|------------------------------------------|
| `development`     | any (usually `develop`)    | Local                  | `config/credentials/development.yml`     |
| `test`            | any                        | Local & GitHub Actions | `config/credentials/test.yml` & `ci.yml` |
| `demo`            | `demo`                     | aws-ideals-demo        | `config/credentials/demo.yml.enc`        |
| `production`      | `production`               | aws-ideals-production  | `config/credentials/production.yml.enc`  |

Files that end in `.enc` are encrypted. Obtain the encryption key for the
corresponding file and then use `rails credentials:edit -e <environment>` to
edit it.

`config/credentials/template.yml` contains the canonical configuration
structure that all config files must use.

`config/credentials/ci.yml` is copied to `test.yml` in continuous integration
(see below).

See the class documentation in `app/config/configuration.rb` for a detailed
explanation of how the configuration system works.

# Documentation

Code documentation uses YARD/Markdown syntax. The `rails doc:generate` command
invokes YARD to generate HTML documentation for the code base.

# Tests & Continuous Integration

Minitest is used for model and controller tests. Some tests depend on
Elasticsearch and most depend on PostgreSQL. `rails test` runs the tests.

There is also a continuous integration setup using
[GitHub Actions](https://github.com/features/actions). The
`.github/workflows/ci.yml` file defines the container fleet, including all
required services such as Elasticsearch and PostgreSQL, which run in separate
containers.
