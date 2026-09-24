# frozen_string_literal: true

namespace :dev do
  namespace :seed do
    desc "Seed a demo institution tree for local development"
    task demo_tree: :environment do
      unless Rails.env.development?
        abort("This task only runs in development.")
      end


      ensure_template_registered_elements!

      institution = find_or_create_demo_institution!

      puts "Using institution: #{institution.name} (id=#{institution.id}, key=#{institution.key})"


      created = {
        units: 0,
        collections: 0,
        items: 0
      }

      ActiveRecord::Base.transaction do
        root_unit = find_or_create_unit!(
          institution: institution,
          title:       "Demo Root Unit",
          parent:      nil,
          created:     created
        )

        sciences = find_or_create_unit!(
          institution: institution,
          title:       "College of Demo Sciences",
          parent:      root_unit,
          created:     created
        )

        humanities = find_or_create_unit!(
          institution: institution,
          title:       "College of Demo Humanities",
          parent:      root_unit,
          created:     created
        )

        biology = find_or_create_unit!(
          institution: institution,
          title:       "Department of Example Biology",
          parent:      sciences,
          created:     created
        )

        chemistry = find_or_create_unit!(
          institution: institution,
          title:       "Department of Example Chemistry",
          parent:      sciences,
          created:     created
        )

        history = find_or_create_unit!(
          institution: institution,
          title:       "Department of Sample History",
          parent:      humanities,
          created:     created
        )

        thesis_collection = find_or_create_collection!(
          institution: institution,
          unit:        biology,
          title:       "Biology Theses and Dissertations",
          created:     created
        )

        article_collection = find_or_create_collection!(
          institution: institution,
          unit:        biology,
          title:       "Biology Articles",
          created:     created
        )

        chemistry_collection = find_or_create_collection!(
          institution: institution,
          unit:        chemistry,
          title:       "Chemistry Technical Reports",
          created:     created
        )

        history_collection = find_or_create_collection!(
          institution: institution,
          unit:        history,
          title:       "History Working Papers",
          created:     created
        )

        submitter = find_seed_submitter!(institution)

        create_demo_item!(
          institution:        institution,
          submitter:          submitter,
          primary_collection: thesis_collection,
          title:              "Effects of Sample Conditions on Test Organisms",
          created:            created
        )

        create_demo_item!(
          institution:        institution,
          submitter:          submitter,
          primary_collection: article_collection,
          title:              "A Demonstration Article for Local Development",
          created:            created
        )

        create_demo_item!(
          institution:        institution,
          submitter:          submitter,
          primary_collection: chemistry_collection,
          title:              "Mock Technical Report on Reproducible Reactions",
          created:            created
        )

        create_demo_item!(
          institution:        institution,
          submitter:          submitter,
          primary_collection: history_collection,
          title:              "Working Paper on the History of Example Repositories",
          created:            created
        )
      end

      puts
      puts "Done."
      puts "Created units: #{created[:units]}"
      puts "Created collections: #{created[:collections]}"
      puts "Created items: #{created[:items]}"
    end

    def ensure_template_registered_elements!
      if RegisteredElement.where(template: true).none?
        require Rails.root.join("lib/seed_data/template_registered_elements")
        SeedData::TemplateRegisteredElements.call
        puts "Created template registered elements"
      end
    end

    def find_or_create_demo_institution!
      Institution.find_by(key: "demo") ||
        Institution.find_by(fqdn: "ideals-ins1.local:3000") ||
        Institution.where("LOWER(name) LIKE ?", "%demo%").first ||
        begin
          institution = Institution.create!(
            key:              "demo",
            fqdn:             "ideals-ins1.local:3000/",
            name:             "Demo Institution",
            service_name:     "Demo IR",
            main_website_url: "http://ideals-ins1.local:3000/",
            feedback_email:   "demo@example.org"
          )
          puts "Created demo institution"
          institution
        end
    end

    def find_or_create_unit!(institution:, title:, parent:, created:)
      scope = Unit.where(institution: institution, title: title)
      scope = parent ? scope.where(parent: parent) : scope.where(parent: nil)
      unit = scope.first

      unless unit
        unit = Unit.create!(
          institution: institution,
          parent:      parent,
          title:       title
        )
        created[:units] += 1
        puts "Created unit: #{title}"
      end

      unit
    end

    def find_or_create_collection!(institution:, unit:, title:, created:)
      collection = Collection.joins(:units)
                             .where(institution: institution, title: title, units: { id: unit.id })
                             .first

      unless collection
        collection = Collection.new(
          institution: institution,
          title:       title
        )
        # Set the primary unit and add the unit to the collection
        collection.primary_unit = unit
        collection.save!
        created[:collections] += 1
        puts "Created collection: #{title}"
      end

      collection
    end

    def find_seed_submitter!(institution)
      User.find_by(email: "demo-seed-submitter@example.org", institution: institution) ||
        User.create!(
          institution: institution,
          email:       "demo-seed-submitter@example.org",
          name:        "Demo Seed Submitter"
        ).tap do
          puts "Created demo submitter"
        end
    end

    def create_demo_item!(institution:, submitter:, primary_collection:, title:, created:)
      existing = Item.joins(:elements)
                     .where(institution: institution, submitter: submitter)
                     .where(ascribed_elements: { string: title })
                     .first

      return existing if existing

      item = CreateItemCommand.new(
        submitter:          submitter,
        institution:        institution,
        primary_collection: primary_collection,
        stage:              Item::Stages::APPROVED,
        event_description:  "Created by dev:seed:demo_tree"
      ).execute

      title_element = institution.title_element
      if title_element
        item.elements.build(
          registered_element: title_element,
          string:             title
        ).save!
      end

      item.assign_handle if item.respond_to?(:assign_handle)
      item.save!

      created[:items] += 1
      puts "Created item: #{title}"

      item
    end
  end
end