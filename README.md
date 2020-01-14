# Ideals

Ideals is the Ruby on Rails web application component of IDEALS, the Illinois
Digital Environment for Access to Learning and Scholarship, which publishes
research and scholarship from the University of Illinois at Urbana-Champaign.

Application documentation is hosted in the
[SCARS Wiki](https://wiki.illinois.edu/wiki/display/scrs/SCARS+Home).

# Configuration

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
