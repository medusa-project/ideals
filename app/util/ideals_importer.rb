##
# Imports content from "Old IDEALS" (IDEALS-DSpace) into the application.
#
class IdealsImporter

  LOGGER = CustomLogger.new(IdealsImporter)

  ##
  # @param pathname [String] Pathname of a directory containing CSV files
  #                          dumped from IDEALS-DSpace.
  #
  def initialize(pathname)
    @pathname = pathname
  end

  def import_collections
    collections = []
    collection2group = {}

    pathname = File.join(@pathname, "collections.csv")
    LOGGER.debug("import_collections(): reading %s (1/3)", pathname)
    row_num = 0
    File.open(pathname, "r").each_line do |line|
      row_num += 1
      next if row_num == 1 # skip header row

      row_arr = line.split("|")
      collection_id = row_arr[0].to_i
      # remove any double quotes from beginning or end of title because messy data
      title = row_arr[1]
      title.strip!
      collections << [collection_id, title]
    end

    pathname = File.join(@pathname, "collection2community.csv")
    LOGGER.debug("import_collections(): reading %s (2/3)", pathname)
    row_num = 0
    File.open(pathname, "r").each_line do |line|
      row_num += 1
      # skip header row
      next if row_num == 1

      row_arr = line.split("|")
      collection_id = row_arr[0].to_i
      group_id = row_arr[1].to_i
      collection2group[collection_id] = group_id
    end

    ActiveRecord::Base.transaction do
      LOGGER.debug("import_collections(): loading collections (3/3)")
      collections.each do |collection|
        col = Collection.create!(id:    collection[0],
                                 title: collection[1])
        col.primary_unit = Unit.find(collection2group[collection[0]])
      end
    end
  end

  def import_handles
    pathname = File.join(@pathname, "handles.csv")
    LOGGER.debug("import_handles(): loading handles from %s", pathname)
    row_num = 0
    ActiveRecord::Base.transaction do
      File.open(pathname, "r").each_line do |line|
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

  def import_items
    pathname = File.join(@pathname, "items.csv")
    LOGGER.debug("import_items(): loading items from %s", pathname)
    item_ids = Set.new
    row_num = 0
    ActiveRecord::Base.transaction do
      File.open(pathname, "r").each_line do |line|
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
        collection_id = row[4].present? ? row[4].to_i : nil
        discoverable = row[5] == "t"
        title = row[6]

        item = Item.create!(id:                      id,
                            title:                   title,
                            submitter_email:         submitter_email,
                            submitter_auth_provider: submitter_auth_provider,
                            in_archive:              in_archive,
                            withdrawn:               withdrawn,
                            discoverable:            discoverable)
        if collection_id.present?
          item.primary_collection = Collection.find(collection_id)
        end
      end
    end
  end

  def import_metadata
    pathname = File.join(@pathname, "metadata_registry.csv")
    LOGGER.debug("import_metadata(): importing %s (1/1)", pathname)
    row_num = 0
    ActiveRecord::Base.transaction do
      RegisteredElement.destroy_all
      File.open(pathname, "r").each_line do |line|
        row_num += 1
        next if row_num == 1 # skip header row

        row_arr = line.split("|")
        name = "#{row_arr[1]}:#{row_arr[2]}"
        name += ":#{row_arr[3]}" if row_arr[3].present?

        RegisteredElement.create!(id:         row_arr[0],
                                  name:       name,
                                  scope_note: row_arr[4])
      end
    end
  end

  def import_units
    communities = []
    community2community = {}

    pathname = File.join(@pathname, "communities.csv")
    LOGGER.debug("import_units(): reading %s (1/3)", pathname)
    row_num = 0
    File.open(pathname, "r").each_line do |line|
      row_num += 1
      next if row_num == 1 # skip header row

      row_arr = line.split("|")
      group_id = row_arr[0].to_i
      # remove any double quotes from beginning or end of title because messy data
      title = row_arr[1]
      title.strip!
      communities << [group_id, title]
    end

    pathname = File.join(@pathname, "community2community.csv")
    LOGGER.debug("import_units(): reading %s (2/3)", pathname)
    row_num = 0
    File.open(pathname, "r").each_line do |line|
      row_num += 1
      # skip header row
      next if row_num == 1

      row_arr = line.split("|")
      group_id = row_arr[0].to_i
      parent_unit_id = row_arr[1].to_i
      community2community[group_id] = parent_unit_id
    end

    ActiveRecord::Base.transaction do
      LOGGER.debug("import_units(): loading units (3/3)")
      communities.each do |community|
        Unit.create!(title:     community[1],
                     id:        community[0],
                     parent_id: community2community[community[0]])
      end
    end
  end

end
