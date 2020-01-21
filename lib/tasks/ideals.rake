require 'rake'

namespace :ideals do

  namespace :cache do
    desc "Clear Rails cache (sessions, views, etc.)"
    task clear: :environment do
      Rails.cache.clear
    end
  end

  namespace :collections do
    desc "Delete all collections"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Collection.all.destroy_all
      end
    end

    # \copy (SELECT collection_id, community_id as unit_id FROM community2collection ORDER BY collection_id) to '/tmp/collection2community.csv' WITH DELIMITER '|' CSV HEADER
    # \copy (SELECT c.collection_id, v.text_value as title FROM collection c INNER JOIN metadatavalue v on (c.collection_id = v.resource_id AND v.resource_type_id=3) INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id) WHERE r.element = 'title' ORDER BY c.collection_id) to '/tmp/collections.csv' WITH DELIMITER '|' CSV HEADER
    desc "Import collections from csv file"
    task import: :environment do
      collections = []
      collection2group = {}

      row_num = 0
      File.open(Rails.root.join("lib", "assets", "import_sources", "collections.csv"), "r").each_line do |line|
        row_num += 1
        next if row_num == 1 # skip header row

        row_arr = line.split("|")
        collection_id = row_arr[0].to_i
        # remove any double quotes from beginning or end of title because messy data
        title = row_arr[1]
        title.strip!
        collections << [collection_id, title]
      end

      row_num = 0
      File.open(Rails.root.join("lib", "assets", "import_sources", "collection2community.csv"), "r").each_line do |line|
        row_num += 1
        # skip header row
        next if row_num == 1

        row_arr = line.split("|")
        collection_id = row_arr[0].to_i
        group_id = row_arr[1].to_i
        collection2group[collection_id] = group_id
      end

      ActiveRecord::Base.transaction do
        collections.each do |collection|
          Collection.create!(id:      collection[0],
                             title:   collection[1],
                             unit_id: collection2group[collection[0]])
        end
      end
    end
  end

  namespace :handles do
    desc "Delete all handles"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Handle.all.destroy_all
      end
    end

    # \copy (select * FROM handle) to '/tmp/handles.csv' csv header
    desc "Import handles from csv file into collection groups"
    task import: :environment do
      row_num = 0
      ActiveRecord::Base.transaction do
        File.open(Rails.root.join("lib", "assets", "import_sources", "handles.csv"), "r").each_line do |line|
          row_num += 1
          next if row_num == 1 # skip header row

          row = line.split(",")
          handle = row[1]
          handle_parts = handle.split("/")
          Handle.create!(id:               row[0].to_i,
                         handle:           handle,
                         prefix:           handle_parts[0].to_i,
                         suffix:           handle_parts[1].to_i,
                         resource_type_id: row[2].to_i,
                         resource_id:      row[3].to_i)
        end
      end
    end
  end

  namespace :items do
    desc "Delete all items"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Item.all.destroy_all
      end
    end

    # \copy (SELECT i.item_id, p.email, i.in_archive, i.withdrawn, i.collection_id, i.discoverable, v.text_value FROM item i INNER JOIN metadatavalue v on (i.item_id = v.resource_id) INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id) INNER JOIN eperson p on (i.submitter_id = p.eperson_id) WHERE v.resource_type_id = 2 AND r.element = 'title' ORDER BY i.item_id) to '/tmp/items.csv' WITH DELIMITER '|' CSV HEADER
    # challenge: titles have commas in them, hence the pipe delimiter
    # some items have multiple titles - just using the first for this toy data - not a real solution
    # This may take 1/2 hour or longer
    desc "Import items from csv file into collection groups"
    task import: :environment do
      item_ids = Set.new
      row_num = 0
      ActiveRecord::Base.transaction do
        File.open(Rails.root.join("lib", "assets", "import_sources", "items.csv"), "r").each_line do |line|
          row_num += 1
          next if row_num == 1 # skip header row

          row = line.split("|")
          id = row[0].to_i
          next if item_ids.include?(id)

          item_ids.add(id)
          submitter_email = row[1]
          next unless submitter_email

          # When this is for real, not just toy records, blank submitter_email is a problem
          email_parts = submitter_email.split("@")
          submitter_auth_provider = if %w(illinois.edu uis.edu uic.edu).include?(email_parts[-1])
                                      AuthProvider::SHIBBOLETH
                                    else
                                      AuthProvider::IDENTITY
                                    end
          in_archive = row[2] == "t"
          withdrawn = row[3] == "t"
          collection_id = row[4].to_i
          discoverable = row[5] == "t"
          title = row[6]

          Item.create!(id:                      id,
                       title:                   title,
                       submitter_email:         submitter_email,
                       submitter_auth_provider: submitter_auth_provider,
                       in_archive:              in_archive,
                       withdrawn:               withdrawn,
                       collection_id:           collection_id,
                       discoverable:            discoverable)
        end
      end
    end

    desc 'Reindex all items'
    task :reindex, [:index_name] => :environment do |task, args|
      Item.reindex_all(args[:index_name])
    end
  end

  namespace :units do
    desc "Delete all units"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Unit.all.destroy_all
      end
    end

    # \copy (SELECT t.community_id, v.text_value FROM community t INNER JOIN metadatavalue v on (t.community_id = v.resource_id and v.resource_type_id = 4) INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id) WHERE r.element = 'title' ORDER BY t.community_id) to '/tmp/communities.csv' WITH DELIMITER '|' CSV HEADER
    # \copy (SELECT child_comm_id as group_id, parent_comm_id as parent_unit_id FROM community2community ORDER BY child_comm_id) to '/tmp/community2community.csv' WITH DELIMITER '|' CSV HEADER
    desc "Import communities from csv files into units"
    task import: :environment do
      communities = []
      community2community = {}

      row_num = 0
      File.open(Rails.root.join("lib", "assets", "import_sources", "communities.csv"), "r").each_line do |line|
        row_num += 1
        next if row_num == 1 # skip header row

        row_arr = line.split("|")
        group_id = row_arr[0].to_i
        # remove any double quotes from beginning or end of title because messy data
        title = row_arr[1]
        title.strip!
        communities << [group_id, title]
      end

      row_num = 0
      File.open(Rails.root.join("lib", "assets", "import_sources", "community2community.csv"), "r").each_line do |line|
        row_num += 1
        # skip header row
        next if row_num == 1

        row_arr = line.split("|")
        group_id = row_arr[0].to_i
        parent_unit_id = row_arr[1].to_i
        community2community[group_id] = parent_unit_id
      end

      ActiveRecord::Base.transaction do
        communities.each do |community|
          Unit.create!(title:          community[1],
                       id:             community[0],
                       parent_unit_id: community2community[community[0]])
        end
      end
    end

    desc 'Reindex all units'
    task :reindex, [:index_name] => :environment do |task, args|
      Unit.reindex_all(args[:index_name])
    end
  end

  namespace :users do
    desc 'Create a user'
    task :create, [:netid, :localpass] => :environment do |task, args|
      netid = args[:netid]
      email = "#{netid}@illinois.edu"
      ActiveRecord::Base.transaction do
        case Rails.env
        when "demo", "production"
          user = User::User.no_omniauth(email, AuthProvider::SHIBBOLETH)
          user.roles << Role.find_by(name: "sysadmin") unless user.sysadmin?
          user.save!
        else
          invitee = Invitee.find_by_email(email) || Invitee.create!(email: email,
                                                                    approval_state: ApprovalState::APPROVED)
          invitee.expires_at = Time.zone.now + 1.years
          invitee.save!
          identity = Identity.find_or_create_by(email: email)
          salt = BCrypt::Engine.generate_salt
          localpass = args[:localpass]
          encrypted_password = BCrypt::Engine.hash_secret(localpass, salt)
          identity.password_digest = encrypted_password
          identity.update(password: localpass, password_confirmation: localpass)
          identity.name = netid
          identity.activated = true
          identity.activated_at = Time.zone.now
          identity.save!
          user = User::User.no_omniauth(email, AuthProvider::IDENTITY)
          user.roles << Role.find_by(name: "sysadmin") unless user.sysadmin?
          user.save!
        end
      end
    end

    desc 'Delete a user'
    task :delete, [:netid] => :environment do |task, args|
      netid = args[:netid]
      email = "#{netid}@illinois.edu"
      ActiveRecord::Base.transaction do
        Identity.destroy_by(name: netid)
        Invitee.destroy_by(email: email)
        User::User.destroy_by(email: email)
      end
    end
  end
end
