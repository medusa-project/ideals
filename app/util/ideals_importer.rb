##
# Imports content from "Old IDEALS" (IDEALS-DSpace) into the application.
#
# This class is intended to be used with a fresh, empty database. It is a
# Singleton because other application component(s) may need to know when it is
# running.
#
# N.B.: methods must be invoked in a certain order. See the
# `ideals_dspace:migrate` rake task.
#
# N.B. 2: methods do not create or update objects within transactions, which
# means that they don't get reindexed. This is in order to save time by
# avoiding multiple indexings of the same object. Resources should be reindexed
# manually after import, perhaps using the `elasticsearch:reindex` rake task.
#
class IdealsImporter

  LOGGER = CustomLogger.new(IdealsImporter)

  include Singleton

  ##
  # @param csv_pathname [String]
  #
  def import_collection_metadata(csv_pathname)
    @running = true
    LOGGER.debug("import_collection_metadata(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    # destroy_all is excruciatingly slow and we don't need callbacks
    AscribedElement.where("collection_id IS NOT NULL").delete_all
    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|")
      collection_id = row_arr[4].to_i
      next if collection_id == 0
      elem_name = "#{row_arr[0]}:#{row_arr[1]}"
      elem_name += ":#{row_arr[2]}" if row_arr[2].present?
      reg_elem = RegisteredElement.find_by_name(elem_name)
      string = row_arr[3].strip

      StringUtils.print_progress(start_time, row_num, line_count,
                                 "Importing collection metadata")

      AscribedElement.create!(registered_element: reg_elem,
                              collection_id: collection_id,
                              string: string)
    end
  ensure
    @running = false
    puts "\n"
  end

  ##
  # @param csv_pathname [String]
  #
  def import_collections(csv_pathname)
    @running = true
    LOGGER.debug("import_collections(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|")

      StringUtils.print_progress(start_time, row_num, line_count,
                                 "Importing collections")
      Collection.create!(id: row_arr[0].to_i)
    end
    update_pkey_sequence("collections")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_collections_2_communities(csv_pathname)
    @running = true
    LOGGER.debug("import_collections_2_communities(): importing %s",
                 csv_pathname)
    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)


    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|")
      collection_id = row_arr[0].to_i
      group_id = row_arr[1].to_i

      StringUtils.print_progress(start_time, row_num, line_count,
                                 "Importing collection-community joins")
      col = Collection.find(collection_id)
      col.primary_unit_id = group_id
      col.save!
    end
    update_pkey_sequence("collections")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_communities(csv_pathname)
    @running = true
    LOGGER.debug("import_communities(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|")
      community_id = row_arr[0].to_i
      title = row_arr[1].strip

      StringUtils.print_progress(start_time, row_num, line_count,
                                 "Importing communities")
      Unit.create!(id: community_id, title: title)
    end
    update_pkey_sequence("units")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_communities_2_communities(csv_pathname)
    @running = true
    LOGGER.debug("import_communities_2_communities(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

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
    update_pkey_sequence("units")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_handles(csv_pathname)
    @running = true
    LOGGER.debug("import_handles(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)


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
    update_pkey_sequence("handles")
  ensure
    puts "\n"
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_item_metadata(csv_pathname)
    @running = true
    LOGGER.debug("import_item_metadata(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    # N.B.: destroy_all is excruciatingly slow and we don't need callbacks
    AscribedElement.where("item_id IS NOT NULL").delete_all
    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|")
      item_id = row_arr[4].to_i
      elem_name = "#{row_arr[0]}:#{row_arr[1]}"
      elem_name += ":#{row_arr[2]}" if row_arr[2].present?
      reg_elem = RegisteredElement.find_by_name(elem_name)
      string = row_arr[3]&.strip
      next unless string.present?

      StringUtils.print_progress(start_time, row_num, line_count,
                                 "Importing item metadata")
      begin
        AscribedElement.create!(registered_element: reg_elem,
                                item_id: item_id,
                                string: string)
      rescue ActiveRecord::RecordInvalid
        # This is probably caused by a nonexistent RegisteredElement. Not much
        # we can do.
      rescue ActiveRecord::InvalidForeignKey
        # IDEALS-DSpace does not have a hard elements-items foreign key and
        # there is some inconsistency, which we have not much choice but to
        # ignore.
      end
    end
  ensure
    puts "\n"
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_items(csv_pathname)
    @running = true
    LOGGER.debug("import_items(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    item_ids = Set.new
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

      StringUtils.print_progress(start_time, row_num, line_count,
                                 "Importing items")
      Item.create!(id:                      id,
                   submitter_email:         submitter_email,
                   submitter_auth_provider: submitter_auth_provider,
                   in_archive:              in_archive,
                   withdrawn:               withdrawn,
                   discoverable:            discoverable,
                   primary_collection_id:   collection_id)
    end
    update_pkey_sequence("items")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_metadata_registry(csv_pathname)
    @running = true
    LOGGER.debug("import_metadata(): importing %s", csv_pathname)

    # Enables progress reporting.
    start_time = Time.now
    line_count = count_lines(csv_pathname)

    RegisteredElement.delete_all
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
    update_pkey_sequence("registered_elements")
  ensure
    puts "\n"
    @running = false
  end

  def running?
    @running
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
