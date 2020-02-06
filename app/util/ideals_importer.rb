##
# Imports content from "Old IDEALS" (IDEALS-DSpace) into the application.
#
class IdealsImporter

  LOGGER = CustomLogger.new(IdealsImporter)

  ##
  # @param csv_pathname [String]
  #
  def import_collections(csv_pathname)
    LOGGER.debug("import_collections(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    ActiveRecord::Base.transaction do
      File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
        next if row_num == 0 # skip header row

        row_arr = line.split("|")
        collection_id = row_arr[0].to_i
        # remove any double quotes from beginning or end of title because messy data
        title = row_arr[1]
        title.strip!

        StringUtils.print_progress(start_time, row_num, line_count,
                                   "Importing collections")
        Collection.create!(id: collection_id, title: title,
                           manager: User.all.find(&:sysadmin?)) # TODO: assign the correct user; this is just some slop to get the import working
      end
      puts "\nReindexing..."
      update_pkey_sequence("collections")
    end
  end

  ##
  # @param csv_pathname [String]
  #
  def import_collections_2_communities(csv_pathname)
    LOGGER.debug("import_collections_2_communities(): importing %s",
                 csv_pathname)
    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    ActiveRecord::Base.transaction do
      File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
        next if row_num == 0 # skip header row

        row_arr = line.split("|")
        collection_id = row_arr[0].to_i
        group_id = row_arr[1].to_i

        StringUtils.print_progress(start_time, row_num, line_count,
                                   "Importing collection-community joins")
        col = Collection.find(collection_id)
        col.primary_unit = Unit.find(group_id)
        col.save!
      end
      puts "\nReindexing..."
      update_pkey_sequence("collections")
    end
  end

  ##
  # @param csv_pathname [String]
  #
  def import_communities(csv_pathname)
    LOGGER.debug("import_communities(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    ActiveRecord::Base.transaction do
      File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
        next if row_num == 0 # skip header row

        row_arr = line.split("|")
        community_id = row_arr[0].to_i
        title = row_arr[1].strip

        StringUtils.print_progress(start_time, row_num, line_count,
                                   "Importing communities")
        Unit.create!(id: community_id, title: title)
      end
      puts "\nReindexing..."
      update_pkey_sequence("units")
    end
  end

  ##
  # @param csv_pathname [String]
  #
  def import_communities_2_communities(csv_pathname)
    LOGGER.debug("import_communities_2_communities(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    ActiveRecord::Base.transaction do
      File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
        next if row_num == 0 # skip header row

        row_arr = line.split("|")
        group_id = row_arr[0].to_i
        parent_unit_id = row_arr[1].to_i

        StringUtils.print_progress(start_time, row_num, line_count,
                                   "Importing community-community joins")
        unit = Unit.find(group_id)
        unit.update!(parent_id: parent_unit_id)
      end
      puts "\nReindexing..."
      update_pkey_sequence("units")
    end
  end

  ##
  # @param csv_pathname [String]
  #
  def import_handles(csv_pathname)
    LOGGER.debug("import_handles(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    ActiveRecord::Base.transaction do
      File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
        next if row_num == 0 # skip header row

        row = line.split(",")
        handle = row[1]
        handle_parts = handle.split("/")

        StringUtils.print_progress(start_time, row_num, line_count,
                                   "Importing handles")
        Handle.create!(id:               row[0].to_i,
                       handle:           handle,
                       prefix:           handle_parts[0].to_i,
                       suffix:           handle_parts[1].to_i,
                       resource_type_id: row[2].to_i,
                       resource_id:      row[3].to_i)
      end
      puts "\n"
      update_pkey_sequence("handles")
    end
  end

  ##
  # @param csv_pathname [String]
  #
  def import_items(csv_pathname)
    LOGGER.debug("import_items(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    item_ids = Set.new
    ActiveRecord::Base.transaction do
      File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
        next if row_num == 0 # skip header row

        row = line.split("|")
        id = row[0].to_i
        next if item_ids.include?(id)

        item_ids.add(id)
        submitter_email = row[1]
        next unless submitter_email

        # TODO: When this is for real, not just toy records, blank submitter_email is a problem
        email_parts = submitter_email.split("@")
        submitter_auth_provider = if %w(illinois.edu uis.edu uic.edu).include?(email_parts[-1])
                                    AuthProvider::SHIBBOLETH
                                  else
                                    AuthProvider::IDENTITY
                                  end
        in_archive    = row[2] == "t"
        withdrawn     = row[3] == "t"
        collection_id = row[4].present? ? row[4].to_i : nil
        discoverable  = row[5] == "t"
        title         = row[6]

        StringUtils.print_progress(start_time, row_num, line_count,
                                   "Importing items")
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
      puts "\nReindexing..."
      update_pkey_sequence("items")
    end
  end

  ##
  # @param csv_pathname [String]
  #
  def import_metadata(csv_pathname)
    LOGGER.debug("import_metadata(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    ActiveRecord::Base.transaction do
      RegisteredElement.destroy_all
      File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
        next if row_num == 0 # skip header row

        row_arr = line.split("|")
        name = "#{row_arr[1]}:#{row_arr[2]}"
        name += ":#{row_arr[3]}" if row_arr[3].present?

        StringUtils.print_progress(start_time, row_num, line_count,
                                   "Importing registered elements")
        RegisteredElement.create!(id:         row_arr[0],
                                  name:       name,
                                  scope_note: row_arr[4])
      end
      puts "\n"
      update_pkey_sequence("registered_elements")
    end
  end

  private

  def count_lines(csv_pathname)
    line_count = 0
    File.open(csv_pathname, "r").each_line do
      line_count += 1
    end
    line_count
  end

  ##
  # Updates a table's primary key sequence to one greater than the largest
  # existing primary key.
  #
  # @param table [String] Table name.
  #
  def update_pkey_sequence(table)
    sql = "SELECT setval(pg_get_serial_sequence('#{table}', 'id'),
                  COALESCE(MAX(id), 1), MAX(id) IS NOT null)
    FROM #{table};"
    ActiveRecord::Base.connection.execute(sql)
  end

end
