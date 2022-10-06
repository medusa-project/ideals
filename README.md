# IDEALS

This is the Ruby on Rails web application component of
[IDEALS](https://www.ideals.illinois.edu), the Illinois Digital Environment for
Access to Learning and Scholarship, which publishes research and scholarship
from the University of Illinois at Urbana-Champaign.

This is a getting-started guide for developers.

# Quick Links

* [GitHub Project](https://github.com/medusa-project/ideals)
* [JIRA Project](https://bugs.library.illinois.edu/projects/IR)
* [Illinois Wiki](https://wiki.illinois.edu//wiki/display/IDEALS/IDEALS+Resources+and+Information)

# Dependencies

* PostgreSQL >= 9.x
* Elasticsearch 7.x with the
  [ICU analysis plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-icu.html)
  installed
* An S3 storage service, such as AWS S3 or [Minio Server](https://min.io)
* VIPS
* Poppler
* RabbitMQ
* A Handle.net server (see the
  [SCARS wiki](https://wiki.illinois.edu/wiki/display/scrs/Setting+Up+the+Handle.net+Software+Locally)
  for setup instructions)

The following sections explain how to get the application working alongside all
of these dependencies, with and without Docker.

# Installation (with Docker)

`./docker-run.sh` will start the application stack in development mode in
Docker. The working copy is mounted in the app container, so changes to
application files will be reflected without restarting.

With that running, skip to the [Migrate Content](#Migrate-content-from-DSpace)
section. The `rails` in the commands must be changed to `./docker-run.sh`, so
`rails <task>` becomes `./docker-run.sh <task>`.

# Installation (without Docker)

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

# Install application gems
$ bundle install
```

## Configure the application

```sh
$ cd config/credentials
$ cp template.yml development.yml
$ cp template.yml test.yml
```
Edit both as necessary. See `template.yml` for documentation of the
configuration format.

## Create the Elasticsearch indexes

```sh
rails elasticsearch:indexes:create[ideals_development]
rails elasticsearch:indexes:create[ideals_test]
```
Note: the index schema may change from time to time. Index schemas can't
generally be changed in place, so a new index has to be created with the new
schema, and then either existing documents migrated into it ("reindexed" in
Elasticsearch terminology), which is fairly quick, or new documents loaded into
it, which is very slow. For the development index, you may prefer to have
separate "blue" and "green" indexes and to switch back-and-forth between them
as needed:

```sh
rails elasticsearch:indexes:create[ideals_blue_development]
rails elasticsearch:indexes:create_alias[ideals_blue_development,ideals_development]
```

Then when you need to create a new index, you can switch to the other color:

```sh
rails elasticsearch:indexes:create[ideals_green_development]
rails elasticsearch:indexes:copy[ideals_blue_development,ideals_green_development]
rails elasticsearch:indexes:delete_alias[ideals_blue_development,ideals_development]
rails elasticsearch:indexes:create_alias[ideals_green_development,ideals_development]
```
(Instead of using aliases, you could also change the `elasticsearch/index` key
in your `development.yml`.)

Note 2: the above does not apply to the test index. This index will be
recreated automatically when the tests are run.

## Configure RabbitMQ

```sh
$ brew install rabbitmq
$ brew services start rabbitmq
# Add /usr/local/sbin to $PATH
$ rabbitmq-plugins enable rabbitmq_management

# Add yourself as an admin user and grant permissions to yourself
$ rabbitmqctl add_user <username> <password>
$ rabbitmqctl set_user_tags <username> administrator
$ rabbitmqctl set_permissions -p / <username> '.*' '.*' '.*'
```
Open the management interface at `http://localhost:15672`. Log in using the
credentials you just created.

In the Queues tab, in the "Add a new queue" section, add two queues named
`ideals_to_medusa` `medusa_to_ideals`, both with default properties. Then
restart RabbitMQ:
```sh
$ brew services restart rabbitmq
```

## Configure the Handle.net server

Refer to the instructions in the
[SCARS wiki](https://wiki.illinois.edu/wiki/display/scrs/Setting+Up+the+Handle.net+Software+Locally).

# Migrate content from DSpace

See [README_MIGRATION.md](README_MIGRATION.md) for detailed information about
the migration process.

Below is a basic summary that will work in development:

```sh
rails elasticsearch:purge
rails storage:purge
rails db:reset
rails dspace:migrate_critical[dbname,dbhost,dbuser,dbpass]
rails ideals:seed_database
rails elasticsearch:reindex[2] # thread count
rails dspace:bitstreams:copy[dspace_ssh_user]
rails dspace:migrate_non_critical[dbname,dbhost,dbuser,dbpass] # optional
rails downloads:compile_monthly_counts # optional, see "Download Statistics" below
rails bitstreams:read_full_text[2] # optional
```

# Create a user account

There are two main categories of accounts: local identity, where account
information is stored locally in the database, and Shibboleth, where account
info is provided by a Shibboleth SP. There are rake tasks to create sysadmins
of both types:

```sh
rails users:create_local_sysadmin[email,password]
rails users:create_shib_sysadmin[netid]
```

# Content Storage

Within the application S3 bucket, content is laid out in the following
structure:

* `institutions/:institution_key/derivatives/:bitstream_id/:crop/:size/default.jpg`
* `institutions/:institution_key/imports/:item_id/`
* `institutions/:institution_key/storage/:item_id/`
* `institutions/:institution_key/uploads/:item_id/`

# Multi-Tenancy

When a request is made to the web app through a reverse proxy server (which is
always expected to be the case in the demo and production environments), the
proxy supplies an `X-Forwarded-Host` header that conveys the fully-qualified
domain name (FQDN) via which the app was accessed. The `current_institution()`
method of `ApplicationController` (and `ApplicationHelper`) returns the
`Institution` model associated with this host+port in order to scope the
content, and customize the theme and some other functionality, to a particular
institution.

To get this working in development, first add a couple of institutions through
the UI, giving them FQDNs of `ideals-ins1.local:3000` and
`ideals-ins2.local:3000`. Then add these to `/etc/hosts`:

```
127.0.0.1 ideals-ins1.local
127.0.0.1 ideals-ins2.local
```

(These hosts also need to be present in the `config.hosts` key in the
`config/environments/*.rb` files.)

Then, you can access
[http://ideals-ins1.local:3000](http://ideals-ins1.local:3000) and
[http://ideals-ins2.local:3000](http://ideals-ins2.local:3000) in order to play
around with multi-tenancy.

# Elasticsearch Schema Migration

From time to time, the index schema may have to change to accommodate new
features. This requires creating a new index using the
`elasticsearch:indexes:create` rake task, changing the index name in the
application configuration (or changing the index alias on the ES side using
the `elasticsearch:indexes:create_alias`/`delete_alias` rake tasks), and then
reindexing all database content using the `elasticsearch:reindex` rake task.

# Branches & Environments

| Rails Environment      | Git Branch              | Machine                | Configuration File                          |
|------------------------|-------------------------|------------------------|---------------------------------------------|
| `development`          | any (usually `develop`) | Local                  | `config/credentials/development.yml`        |
| `development` (Docker) | any (usually `develop`) | Docker                 | `config/credentials/development-docker.yml` |
| `test`                 | any                     | Local & GitHub Actions | `config/credentials/test.yml` & `ci.yml`    |
| `test` (Docker)        | any                     | Docker                 | `config/credentials/test-docker.yml`        |
| `demo`                 | `demo`                  | aws-ideals-demo        | `config/credentials/demo.yml.enc`           |
| `carli_demo`           | `carli_demo`            | aws-scholarship-demo   | `config/credentials/carli_demo.yml.enc`
| `production`           | `production`            | aws-ideals-production  | `config/credentials/production.yml.enc`     |

Files that end in `.enc` are encrypted. Obtain the encryption key from a
project team member and then use `rails credentials:edit -e <environment>`
to edit it.

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

Minitest is used for model and controller tests. `rails test` runs the tests.

Tests may depend on any or all of the dependent services (Elasticsearch,
RabbitMQ, etc.). It's perfectly legitimate to install all of that stuff on your
local machine and run the tests there. You can also use `docker compose`, which
will initialize a container, copy the code base into it, spin up all of the
service containers, and run the tests:

```sh
$ ./docker-test.sh
```

This is how tests are run in continuous integration, which uses
[GitHub Actions](https://github.com/features/actions).
