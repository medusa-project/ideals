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

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    # destroy_all is excruciatingly slow and we don't need callbacks
    AscribedElement.where("collection_id IS NOT NULL").delete_all
    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr       = line.split("|").map(&:strip)
      collection_id = row_arr[4].to_i
      next if collection_id == 0

      elem_name = "#{row_arr[0]}:#{row_arr[1]}"
      elem_name += ":#{row_arr[2]}" if row_arr[2].present?
      reg_elem  = RegisteredElement.find_by_name(elem_name)
      string    = row_arr[3].strip

      progress.report(row_num, "Importing collection metadata")

      AscribedElement.create!(registered_element: reg_elem,
                              collection_id: collection_id,
                              string: string)
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_collections(csv_pathname)
    @running = true
    LOGGER.debug("import_collections(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row
      row_arr = line.split("|").map(&:strip)
      progress.report(row_num, "Importing collections")
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
    line_count = count_lines(csv_pathname)
    progress = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr       = line.split("|").map(&:strip)
      collection_id = row_arr[0].to_i
      group_id      = row_arr[1].to_i

      progress.report(row_num, "Importing collection-community joins")
      col = Collection.find(collection_id)
      col.update!(primary_unit_id: group_id)
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

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr      = line.split("|").map(&:strip)
      community_id = row_arr[0].to_i
      title        = row_arr[1].strip

      progress.report(row_num, "Importing communities")
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

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr        = line.split("|").map(&:strip)
      group_id       = row_arr[0].to_i
      parent_unit_id = row_arr[1].to_i

      progress.report(row_num, "Importing community-community joins")
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

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row          = line.split(",")
      handle       = row[1]
      handle_parts = handle.split("/")

      progress.report(row_num, "Importing handles")
      Handle.create!(id:               row[0].to_i,
                     handle:           handle,
                     prefix:           handle_parts[0].to_i,
                     suffix:           handle_parts[1].to_i,
                     resource_type_id: row[2].to_i,
                     resource_id:      row[3].to_i)
    end
    update_pkey_sequence("handles")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_item_metadata(csv_pathname)
    @running = true
    LOGGER.debug("import_item_metadata(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    # N.B.: destroy_all is excruciatingly slow and we don't need callbacks
    AscribedElement.where("item_id IS NOT NULL").delete_all
    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr   = line.split("|").map(&:strip)
      item_id   = row_arr[4].to_i
      elem_name = "#{row_arr[0]}:#{row_arr[1]}"
      elem_name += ":#{row_arr[2]}" if row_arr[2].present?
      reg_elem  = RegisteredElement.find_by_name(elem_name)
      string    = row_arr[3]&.strip
      next unless string.present?

      progress.report(row_num, "Importing item metadata")
      begin
        AscribedElement.create!(registered_element: reg_elem,
                                item_id: item_id,
                                string: string)
      rescue ActiveRecord::RecordInvalid
        # This may be caused by either a nonexistent RegisteredElement, or a
        # nonexistent Item. Not much we can do in either case.
      rescue ActiveRecord::InvalidForeignKey
        # IDEALS-DSpace does not have a hard elements-items foreign key and
        # there is some inconsistency, which we have not much choice but to
        # ignore.
      end
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_items(csv_pathname)
    @running = true
    LOGGER.debug("import_items(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row           = line.split("|").map(&:strip)
      id            = row[0].to_i
      submitter_id  = row[1]
      in_archive    = row[2] == "t"
      withdrawn     = row[3] == "t"
      collection_id = row[4].present? ? row[4].to_i : nil
      discoverable  = row[5] == "t"

      # Skip submitterless items (items whose submitting user has not been
      # imported due to not being a UofI user). This is temporary.
      if User.find_by(id: submitter_id)
        Item.create!(id:                    id,
                     submitter_id:          submitter_id,
                     in_archive:            in_archive,
                     withdrawn:             withdrawn,
                     discoverable:          discoverable,
                     primary_collection_id: collection_id)
      end
      progress.report(row_num, "Importing items")
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

    line_count = count_lines(csv_pathname)
    progress = Progress.new(line_count)

    RegisteredElement.delete_all
    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|").map(&:strip)
      name    = "#{row_arr[1]}:#{row_arr[2]}"
      name    += ":#{row_arr[3]}" if row_arr[3].present?

      progress.report(row_num, "Importing registered elements")
      RegisteredElement.create!(id:         row_arr[0],
                                name:       name,
                                uri:        "http://example.org/#{name}",
                                label:      "Label For #{name}",
                                scope_note: row_arr[4])
    end
    update_pkey_sequence("registered_elements")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_user_metadata(csv_pathname)
    @running = true
    LOGGER.debug("import_user_metadata(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress = Progress.new(line_count)

    # This technique is quite inefficient, but Postgres does not make pivot
    # queries easy...
    users = Set.new
    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr   = line.split("|").map(&:strip)
      user_id   = row_arr[0].to_i
      elem_name = row_arr[1]
      value     = row_arr[2]
      next unless elem_name.present? && value.present?

      user = users.find{ |u| u[:id] == user_id }
      unless user
        user = { id: user_id }
        users << user
      end

      case elem_name
      when "firstname"
        user[:first_name] = value.strip
      when "lastname"
        user[:last_name] = value.strip
      when "phone"
        user[:phone] = value.strip
      when "language"
        user[:language] = value.strip
      end

      progress.report(row_num, "Importing user metadata (1/2)")
    end

    progress = Progress.new(users.length)
    users.each_with_index do |user_info, index|
      new_name = "#{user_info[:first_name]} #{user_info[:last_name]}"
      if new_name.present?
        begin
          user = User.find(user_info[:id])
          user.update!(name: new_name,
                       phone: user_info[:phone]) # TODO: language?
        rescue ActiveRecord::RecordNotFound
          # This is expected to be quite common as we are currently importing
          # only UofI users.
        end
      end
      progress.report(index + 1, "Importing user metadata (2/2)")
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_users(csv_pathname)
    @running = true
    LOGGER.debug("import_users(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row = line.split("|").map(&:strip)
      id  = row[0].to_i
      # The eperson table contains all kinds of crap. Some of the email
      # addresses are invalid and some are in "spam avoidance format," like
      # "user at uiuc dot edu". For now, we're going to import only UofI users.
      email = row[1].strip.
          gsub('"', "").
          gsub(/(\w+) at (\w+) dot (\w+)/, "\\1@\\2.\\3")
      next if email.blank?
      email_parts = email.split("@")
      username    = email_parts[0]
      tld         = email.scan(/(\w+).(\w+)$/).last.join(".")

      if %w(illinois.edu uillinois.edu uiuc.edu).include?(tld)
        unless User.find_by_email(email)
          ShibbolethUser.create!(id:       id,
                                 uid:      email,
                                 email:    email,
                                 name:     username,
                                 username: username)
        end
      elsif email == "robbins.sd@gmail.com"
        # Many items were bulk-imported into IDEALS-DSpace under this email.
        unless User.find_by_email(email)
          IdentityUser.create!(id:       id,
                               uid:      email,
                               email:    email,
                               name:     "Seth Robbins",
                               username: username)
        end
      end
      progress.report(row_num, "Importing users")
    end
    update_pkey_sequence("users")
  ensure
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
