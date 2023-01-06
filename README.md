# IDEALS

This is the Ruby on Rails web application component of
[IDEALS](https://www.ideals.illinois.edu), the Illinois Digital Environment for
Access to Learning and Scholarship, which publishes research and scholarship
from the University of Illinois at Urbana-Champaign.

This is a getting-started guide and brief technical manual for developers.

# Quick Links

* [GitHub Project](https://github.com/medusa-project/ideals)
* [GitHub Issues](https://github.com/medusa-project/ideals-issues)
* [Illinois Wiki](https://wiki.illinois.edu//wiki/display/IDEALS/IDEALS+Resources+and+Information)

# Table of Contents

* [GettingStarted](#GettingStarted)
    * [Dependencies](#Dependencies)
    * [InstallationWithDocker](#InstallationWithDocker)
    * [InstallationWithoutDocker](#InstallationWithoutDocker)
* [DesignConcepts](#DesignConcepts)
    * [Authorization](#Authorization) 
    * [ContentStorage](#ContentStorage)
    * [OpenSearch](#OpenSearch)
    * [AsynchronousJobs](#AsynchronousJobs)
    * [JavaScript](#JavaScript)
    * [ModalWindows](#ModalWindows)
    * [Handles](#Handles)
    * [FileFormatSupport](#FileFormatSupport)
    * [Multi-Tenancy](#Multi-Tenancy)
    * [Stylesheets](#Stylesheets)
* [BranchesAndEnvironments](#BranchesAndEnvironments)
* [OpenSearchSchemaMigration](#OpenSearchSchemaMigration)
* [CodeDocumentation](#CodeDocumentation)
* [TestsAndContinuousIntegration](#TestsAndContinuousIntegration)

# GettingStarted

## Dependencies

* PostgreSQL >= 9.x
* OpenSearch 1.x with the `analysis-icu` plugin installed
* An S3 storage service, such as AWS S3 or [Minio Server](https://min.io)
* VIPS
* Poppler or xpdf (for the `pdftotext` tool)
* RabbitMQ
* A Handle.net server (see the
  [SCARS wiki](https://wiki.illinois.edu/wiki/display/scrs/Setting+Up+the+Handle.net+Software+Locally)
  for setup instructions)

The following sections explain how to get the application working alongside all
of these dependencies, with and without Docker.

## InstallationWithDocker

`./docker-run.sh` will start the application stack in development mode in
Docker. The working copy is mounted in the app container, so changes to
application files will be reflected without restarting.

With that running, skip to the [Migrate Content](#Migrate-content-from-DSpace)
section, if you want to do that. The `rails` in the commands must be changed to
`./docker-run.sh`, so `rails <task>` becomes `./docker-run.sh <task>`.

## InstallationWithoutDocker

### Install everything

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

### Configure the application

```sh
$ cd config/credentials
$ cp template.yml development.yml
$ cp template.yml test.yml
```
Edit both as necessary. See `template.yml` for documentation of the
configuration format.

### Create the OpenSearch indexes

```sh
rails opensearch:indexes:create[ideals_development]
rails opensearch:indexes:create[ideals_test]
```
Note: the index schema may change from time to time. Index schemas can't
generally be changed in place, so a new index has to be created with the new
schema, and then either existing documents migrated into it ("reindexed" in
OpenSearch terminology), which is fairly quick, or new documents loaded into
it, which is very slow. For the development index, you may prefer to have
separate "blue" and "green" indexes and to switch back-and-forth between them
as needed:

```sh
rails opensearch:indexes:create[ideals_blue_development]
rails opensearch:indexes:create_alias[ideals_blue_development,ideals_development]
```

Then when you need to create a new index, you can switch to the other color:

```sh
rails opensearch:indexes:create[ideals_green_development]
rails opensearch:indexes:copy[ideals_blue_development,ideals_green_development]
rails opensearch:indexes:delete_alias[ideals_blue_development,ideals_development]
rails opensearch:indexes:create_alias[ideals_green_development,ideals_development]
```
(Instead of using aliases, you could also change the `opensearch/index` key
in your `development.yml`.)

Note 2: the above does not apply to the test index. This index will be
recreated automatically when the tests are run.

### Configure RabbitMQ

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

### Configure the Handle.net server

Refer to the instructions in the
[SCARS wiki](https://wiki.illinois.edu/wiki/display/scrs/Setting+Up+the+Handle.net+Software+Locally).

### Create a user account

There are two main categories of accounts: local identity, where account
information is stored locally in the database, and Shibboleth, where account
info is provided by a Shibboleth SP. There are rake tasks to create sysadmins
of both types, but in your local environment, you would only be using the local
kind:

```sh
rails users:create_local_sysadmin[email,password,name,institution_key]
```

# DesignConcepts

## Authorization

Upon each request, a `before_filter` in ApplicationController instantiates a
policy class corresponding to that controller (these classes are located in
`app/policies`) and invokes one of its methods corresponding to the controller
method. This method may return a hash like:

```ruby
{authorized: true}
```

Or, if authorization fails, it will return a hash like:

```
{
  authorized: false,
  reason: "This user is not allowed to do such and such."
}
```

A `policy()` method in ApplicationHelper provides convenient access to the
policy object, where it can be accessed from views as well. For example, there
may be a policy method called `show()` that authorizes access to a show view,
but the current user does not have sufficient privileges to see a particular
element in the template, so it is nested under a conditional like:

```haml
- if policy(@model).see_privileged_thing?
  ...
```

The policy architecture is very similar to what is provided by the
[Pundit](https://github.com/varvet/pundit) gem, but Pundit doesn't support
failure reasons.

See the ApplicationPolicy class for more information.

## ContentStorage

Within the application S3 bucket, content is laid out in the following
structure:

* `institutions/:institution_key/derivatives/:bitstream_id/:crop/:size/default.jpg`
* `institutions/:institution_key/imports/:item_id/`
* `institutions/:institution_key/storage/:item_id/`
* `institutions/:institution_key/uploads/:item_id/`

The high-level PersistentStore class provides access to the bucket and objects
within it. This class wraps the S3Client class, which itself is a convenience
wrapper around an Aws::S3::Client from the `aws-sdk-s3` gem.

## OpenSearch

OpenSearch handles most searching in the application, providing natural-order
sorting, relevance ranking and weighting (boosts), and facets (a.k.a.
aggregations). It also enables complex queries that would be difficult using
PostgreSQL alone.

There are two aspects to OpenSearch support: indexing (sending documents to
OpenSearch) and querying.(getting them out).

### Indexing

Every model class to be indexed includes the Indexed concern, which provides
several indexing-related methods. One of them in particular,
`as_indexed_json()`, gets overridden by every including class to return a hash
that will automatically get converted into an OpenSearch document and sent to
OpenSearch upon invocation of the model's `reindex()` method (also supplied by
Indexed).

On the OpenSearch side, documents get ingested into an index which has a
particular schema. By default, OpenSearch wants to auto-detect the data types
using in the various fields, but this application requires more precise
control, so all auto-detection is disabled and a fixed schema is used instead.
This schema resides in `search/index_schema.yml` and gets sent to OpenSearch
upon index creation (using the `opensearch:indexes:create` rake task).

### Querying

The queries that the application needs to send to OpenSearch tend to be very
long and complicated. The Indexed concern also provides a `search()` class
method that returns one of the AbstractRelation implementations. These work
similar to ActiveRecord::Relation, using the Builder pattern to greatly
simplify the process of searching.

Indexing and searching features both rely on the OpenSearchClient class, which
is basically just a high-level HTTP client geared toward interacting with
OpenSearch.

There are also several OpenSearch-related rake tasks under the `opensearch:`
prefix that can assist with index management and reindexing.

## AsynchronousJobs

In order to keep the web server responsive, all operations that would take more
than a small fraction of a second to complete need to run asynchronously. This
is accomplished using Rails' ActiveJob feature.

The async adapter is used to run jobs. This adapter simply runs them in a
separate thread within one of the web server's worker processes, with no fancy
features like retrying failed jobs etc. The jobs that IDEALS runs are trivial
enough that this works well without adding the complexity of another
dependency like Redis, beanstalkd, etc. that many other adapters require.

Examining the job classes in `app/jobs`, one will notice that most of their
`perform()` methods create a Task instance before doing anything. This object
enables progress reporting from the institution-scoped `/tasks` or global-
scoped `/all-tasks` views.

## JavaScript

The JavaScript system uses Sprockets, which was the default in earlier versions
of Rails, and is nice and simple. In this system, JavaScript files are
organized roughly per-controller. (`ideals.js` contains shared code that they
can all use.)

Within each JavaScript file, there are one or more functions followed by an
on-document-ready function that checks the HTML `<body>` ID to decide which
one to instantiate. This works like:

```haml
-# something/show.html.haml, rendered by SomethingController.show()
- provide :body_id, "show_something"
```

```javascript
// javascripts/something.js
$(document).ready(function() {
    if ($(body).attr("id") === "show_something") {
        // ...
    }
});
```

## ModalWindows

The web application makes heavy use of modal windows, mainly for contextual
forms. The content for most modals is loaded on-demand via XHR which enables
the rest of the page to load faster. The basic idea is, from a template, to
require `shared/ajax_modal`:

```haml
= render partial: "shared/ajax_modal",
         locals:  { id:    "add-child-unit-modal",
                    title: "Add Child Unit" }
```

This will give you nothing more than an empty, hidden modal. Next, we add a
button (in the same template) to open it:

```haml
%button.btn.btn-light.add-child-unit{"data-unit-id":   @unit.id,
                                     "data-bs-target": "#add-child-unit-modal",
                                     "data-bs-toggle": "modal",
                                     role:             "button"}
  %i.fa.fa-plus
  Add Child Unit
```

Now the modal can open, but it's still empty. So we add some JavaScript to fill
in its body (the div with class `modal-body`) when it opens (or when the button
that opens it is clicked):

```javascript
$(".add-child-unit").on("click", function() {
    const url = "/units/new?parent_id=" + unitID;
    $.get(url, function(data) {
        $("#add-child-unit-modal .modal-body").html(data);
    });
});
```

Of course, the `/units/new` route here must supply the necessary form partial.

## Handles

When a unit or collection is created, or item is approved, a handle for it is
created on the Handle.net server and a record of this handle is saved in the
`handles` table. In production, this enables these entities to be resolved
using the [hdl.handle.net](https://hdl.handle.net) service.

## FileFormatSupport

The `config/formats.yml` file defines all of the file formats recognized by the
application.

The format of user-submitted files is inferred by their filename extension.
Users can submit files in any format, whether or not they are defined in this
file, and formats can be added ex post facto to support already-submitted
files.

Sysadmins can access a web-based interface to the `formats.yml` file at
`/file-formats`. This is useful for finding formats that are not yet supported
but need to be.

## Multi-Tenancy

When a request is made to the web app through a reverse proxy server (which is
always expected to be the case in the demo and production environments), the
proxy supplies an `X-Forwarded-Host` header that conveys the fully-qualified
domain name (FQDN) via which the app was accessed. There are two possibilities:

1. This FQDN matches one of the registered Institution FQDNs, in which case
   the request is considered to be institution-scoped and the current
   Institution model can be acquired from the the `current_institution()`
   method of `ApplicationController` (and `ApplicationHelper`). Most routes
   are scoped like this.
2. This FQDN does not match a registered institution FQDN, in which case the
   request is considered to be in global scope. In this case,
   `ApplicationController.institution_scope?()` returns false and there is no
   relevant Institution model. (`current_institution()` should not be used.)
   Only a few routes are globally scoped.

To get this working in development, first add a couple of institutions through
the UI, giving them FQDNs of `ideals-ins1.local:3000` and
`ideals-ins2.local:3000`. Then add these to `/etc/hosts`:

```
127.0.0.1 ideals-ins1.local
127.0.0.1 ideals-ins2.local
```

(These hosts also need to be present in the `config.hosts` key in the
`config/environments/development.rb` file, which they are by default.)

Then, you can access
[http://ideals-ins1.local:3000](http://ideals-ins1.local:3000) and
[http://ideals-ins2.local:3000](http://ideals-ins2.local:3000) in order to play
around with multi-tenancy. You can still access
[http://localhost:3000](http://localhost:3000) as usual to see the global
scope.

## Stylesheets

IDEALS is a Sprockets-based app, like apps of earlier Rails versions used to
be. There is a Bootstrap gem specified in the Gemfile and the stylesheet from
that is imported into the `application.scss`. There are some other global,
non-institution-specific style overrides in the same folder.

Institution-specific styles are handled differently: an institution can choose
various colors etc. through the UI, which are injected into its own custom
stylesheet provided by StylesheetsController. This gets overlaid onto the base
Bootstrap+global custom styles mentioned above.

# BranchesAndEnvironments

There are three main Git branches, which correspond to the environments in
which the application runs: locally, in demo, and in production. Branching
generally happens like this:

```
develop -----> demo -----> production
   ^                           |
   |                           |
   |---------------------------|
```


| Rails Environment      | Git Branch              | Machine                    | Configuration File                            |
|------------------------|-------------------------|----------------------------|-----------------------------------------------|
| `development`          | any (usually `develop`) | Local                      | `config/credentials/development.yml`          |
| `development` (Docker) | any (usually `develop`) | Docker                     | `config/credentials/development-docker.yml`   |
| `test`                 | any                     | Local & GitHub Actions     | `config/credentials/test.yml` & `ci.yml`      |
| `test` (Docker)        | any                     | Docker                     | `config/credentials/test-docker.yml`          |
| `demo`                 | `demo`                  | aws-ideals-demo            | `config/credentials/demo.yml.enc`             |
| `production`           | `production`            | aws-ideals-production      | `config/credentials/production.yml.enc`       |

Files that end in `.enc` are encrypted. Obtain the encryption key from a
project team member and then use `rails credentials:edit -e <environment>`
to edit it.

`config/credentials/template.yml` contains the canonical configuration
structure that all config files must use.

`config/credentials/ci.yml` is copied to `test.yml` in continuous integration
(see below).

See the class documentation in `app/models/configuration.rb` for a detailed
explanation of how the configuration system works.

# OpenSearchSchemaMigration

From time to time, the index schema may have to change to accommodate new
features. This requires creating a new index using the
`opensearch:indexes:create` rake task, changing the index name in the
application configuration (or changing the index alias on the OpenSearch side
using the `opensearch:indexes:create_alias`/`delete_alias` rake tasks), and
then reindexing all database content using the `opensearch:reindex` rake task.

# CodeDocumentation

Code documentation uses YARD/Markdown syntax. The `rails doc:generate` command
invokes YARD to generate HTML documentation for the code base.

# TestsAndContinuousIntegration

Minitest is used for model and controller tests. `rails test` runs the tests.

Tests may depend on any or all of the dependent services (OpenSearch,
RabbitMQ, etc.). It's perfectly legitimate to install all of that stuff on your
local machine and run the tests there. You can also use `docker compose`, which
will initialize a container, copy the code base into it, spin up all of the
service containers, and run the tests:

```sh
$ ./docker-test.sh
```

This is how tests are run in continuous integration, which uses
[GitHub Actions](https://github.com/features/actions).
