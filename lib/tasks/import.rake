# frozen_string_literal: true

require "csv"
namespace :import do
  desc "delete all units"
  task delete_units: :environment do
    Unit.all.destroy_all
  end

  desc "delete all collections"
  task delete_collections: :environment do
    Collection.all.destroy_all
  end

  desc "delete all items"
  task delete_items: :environment do
    Item.all.destroy_all
  end

  desc "delete all handles"
  task delete_handles: :environment do
    Handle.all.destroy_all
  end

  # \copy (SELECT t.community_id, v.text_value FROM community t INNER JOIN metadatavalue v on (t.community_id = v.resource_id and v.resource_type_id = 4) INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id) WHERE r.element = 'title' ORDER BY t.community_id) to '/tmp/communities.csv' WITH DELIMITER '|' CSV HEADER
  # \copy (SELECT child_comm_id as group_id, parent_comm_id as parent_unit_id FROM community2community ORDER BY child_comm_id) to '/tmp/community2community.csv' WITH DELIMITER '|' CSV HEADER
  desc "import communities from csv files into units"
  task units: :environment do
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

    communities.each do |community|
      Unit.create(title:          community[1],
                  id:             community[0],
                  parent_unit_id: community2community[community[0]])
    end
  end

  # \copy (select * FROM handle) to '/tmp/handles.csv' csv header
  desc "import handles from csv file into collection groups"
  task handles: :environment do
    row_num = 0
    File.open(Rails.root.join("lib", "assets", "import_sources", "handles.csv"), "r").each_line do |line|
      row_num += 1
      next if row_num == 1 # skip header row

      row = line.split(",")
      handle = row[1]
      handle_parts = handle.split("/")
      Handle.create(id:               row[0].to_i,
                    handle:           handle,
                    prefix:           handle_parts[0].to_i,
                    suffix:           handle_parts[1].to_i,
                    resource_type_id: row[2].to_i,
                    resource_id:      row[3].to_i)
    end
  end

  # \copy (SELECT i.item_id, p.email, i.in_archive, i.withdrawn, i.collection_id, i.discoverable, v.text_value FROM item i INNER JOIN metadatavalue v on (i.item_id = v.resource_id) INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id) INNER JOIN eperson p on (i.submitter_id = p.eperson_id) WHERE v.resource_type_id = 2 AND r.element = 'title' ORDER BY i.item_id) to '/tmp/items.csv' WITH DELIMITER '|' CSV HEADER
  # challenge: titles have commas in them, hence the pipe delimiter
  # some items have multiple titles - just using the first for this toy data - not a real solution
  desc "import items from csv file into collection groups"
  task items: :environment do
    item_ids = Set.new
    row_num = 0
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
      submitter_auth_provider = if ["illinois.edu", "uis.edu", "uic.edu"].include?(email_parts[-1])
                                  Ideals::AuthProvider::SHIBBOLETH
                                else
                                  Ideals::AuthProvider::IDENTITY
                                end
      in_archive = row[2] == "t"
      withdrawn = row[3] == "t"
      collection_id = row[4].to_i
      discoverable = row[5] == "t"
      title = row[6]
      Item.create(id:                      id,
                  title:                   title,
                  submitter_email:         submitter_email,
                  submitter_auth_provider: submitter_auth_provider,
                  in_archive:              in_archive,
                  withdrawn:               withdrawn,
                  collection_id:           collection_id,
                  discoverable:            discoverable)
    end
  end

  # \copy (SELECT collection_id, community_id as unit_id FROM community2collection ORDER BY collection_id) to '/tmp/collection2community.csv' WITH DELIMITER '|' CSV HEADER
  # \copy (SELECT c.collection_id, v.text_value as title FROM collection c INNER JOIN metadatavalue v on (c.collection_id = v.resource_id AND v.resource_type_id=3) INNER JOIN metadatafieldregistry r on (v.metadata_field_id = r.metadata_field_id) WHERE r.element = 'title' ORDER BY c.collection_id) to '/tmp/collections.csv' WITH DELIMITER '|' CSV HEADER
  desc "import collections from csv file"
  task collections: :environment do
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

    collections.each do |collection|
      Collection.create(id:      collection[0],
                        title:   collection[1],
                        unit_id: collection2group[collection[0]])
    end
  end
end
