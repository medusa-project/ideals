##
# Imports content from DSpace into the application. Methods work in conjunction
# with the SQL scripts in the `scripts` directory.
#
# The main entry point into the migration system is not via this class, but
# rather via the `dspace` rake tasks. See that file for detailed documentation
# of the migration tools & process.
#
# An import can be run into a fresh destination database, or into a destination
# database already populated with content, in order to pick up content added to
# the source database since the last import.
#
# This is a Singleton class because other application components may need to
# know when it is running.
#
# N.B.: methods must be invoked in a certain order. See the
# `dspace:migrate_critical` and `dspace:migrate_non_critical` rake tasks.
#
# N.B. 2: methods do not create or update objects within transactions, which
# means that objects don't get indexed. This is in order to save time by
# avoiding multiple indexings of the same object. Resources should be indexed
# manually after import, perhaps using the `elasticsearch:reindex` rake task.
#
class DspaceImporter

  LOGGER = CustomLogger.new(DspaceImporter)

  include Singleton

  ##
  # @param csv_pathname [String]
  #
  def import_bitstreams(csv_pathname)
    @running = true
    LOGGER.debug("import_bitstreams(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row
      row_arr = line.split("|").map(&:strip)
      progress.report(row_num, "Importing bitstreams")
      begin
        Bitstream.where(id: row_arr[1].to_i).first_or_create!(
          item_id:   row_arr[0].to_i,
          dspace_id: row_arr[2],
          length:    row_arr[3].to_i,
          primary:   row_arr[4].present?)
      rescue ActiveRecord::RecordInvalid
        $stderr.puts "import_bitstreams(): invalid: #{row_arr}"
      end
    end
    update_pkey_sequence("bitstreams")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_bitstream_bundles(csv_pathname)
    @running = true
    LOGGER.debug("import_bitstream_bundles(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|").map(&:strip)
      bs_id   = row_arr[1].to_i
      string  = row_arr[0]&.strip

      progress.report(row_num, "Importing bitstream bundles")
      begin
        b = Bitstream.find(bs_id)
        if b.original_filename&.downcase == "license.txt"
          bundle = Bitstream::Bundle::LICENSE
        elsif b.original_filename&.downcase&.end_with?(".pdf")
          bundle = Bitstream::Bundle::CONTENT
        else
          case string
          when "LICENSE"
            bundle = Bitstream::Bundle::LICENSE
          when "METADATA"
            bundle = Bitstream::Bundle::METADATA
          when "ORIGINAL"
            bundle = Bitstream::Bundle::CONTENT
          when "TEXT"
            bundle = Bitstream::Bundle::TEXT
          when "CONVERSION"
            bundle = Bitstream::Bundle::CONVERSION
          when "THUMBNAIL"
            bundle = Bitstream::Bundle::THUMBNAIL
          when "ARCHIVE"
            bundle = Bitstream::Bundle::ARCHIVE
          when "SOURCE"
            bundle = Bitstream::Bundle::SOURCE
          when "BRANDED_PREVIEW"
            bundle = Bitstream::Bundle::BRANDED_PREVIEW
          when "NOTES"
            bundle = Bitstream::Bundle::NOTES
          when "SWORD"
            bundle = Bitstream::Bundle::SWORD
          else
            raise ArgumentError, "Unrecognized bundle: #{string}"
          end
        end
        b.update!(bundle: bundle) if b.bundle != bundle
      rescue ActiveRecord::RecordNotFound
        # The Bitstream does not exist. This implies an inconsistent source
        # database; there is not much we can do.
      end
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_bitstream_metadata(csv_pathname)
    @running = true
    LOGGER.debug("import_bitstream_metadata(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr   = line.split("|").map(&:strip)
      bs_id     = row_arr[4].to_i
      elem_name = "#{row_arr[0]}:#{row_arr[1]}"
      elem_name += ":#{row_arr[2]}" if row_arr[2].present?
      next unless %w(dc:title dc:description).include?(elem_name)
      string    = row_arr[3]&.strip
      next unless string.present?

      progress.report(row_num, "Importing bitstream metadata")
      begin
        b = Bitstream.find(bs_id)
        case elem_name
        when "dc:description"
          b.update!(description: string)
        when "dc:title"
          b.update!(original_filename: string)
        end
      rescue ActiveRecord::RecordNotFound
        # This may be caused by a nonexistent Bitstream. Not much we can do.
      end
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_bitstream_statistics(csv_pathname)
    @running = true
    LOGGER.debug("import_bitstream_statistics(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr = line.split("|").map(&:strip)
      bs_id   = row_arr[0].to_i
      month   = Time.parse(row_arr[1])
      count   = row_arr[2].to_i

      progress.report(row_num, "Importing bitstream statistics")
      if Bitstream.exists?(bs_id)
        count.times do
          Event.create!(bitstream_id: bs_id,
                        happened_at:  month,
                        event_type:   Event::Type::DOWNLOAD,
                        description:  "Imported download from DSpace")
        end
      end
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
      row_arr       = line.split("|").map(&:strip)
      collection_id = row_arr[0].to_i

      progress.report(row_num, "Importing collections (1/2)")
      begin
        collection = Collection.where(id: collection_id).first_or_initialize
        elem_name  = row_arr[1]
        elem_name += ":#{row_arr[2]}" if row_arr[2].present?
        # Replace @@@@ with newline, strip leading and trailing quote,
        # and double quotes.
        string = row_arr[3]&.strip&.gsub("@@@@", "\n")&.gsub(/^"/, "")&.gsub(/"$/, "")&.gsub('""', '"')
        if string.present?
          case elem_name
          when "description"
            collection.introduction = string
          when "description:abstract"
            collection.short_description = string
          when "provenance"
            collection.provenance = string
          when "rights"
            collection.rights = string
          when "title"
            collection.title = string
          end
        end
        collection.save!
      rescue ActiveRecord::RecordNotUnique
        # nothing we can do
      end
    end

    update_pkey_sequence("collections")

    LOGGER.debug("import_collections(): creating unit default collections")
    progress = Progress.new(Unit.count)
    Unit.all.each_with_index do |unit, index|
      unit.create_default_collection
      progress.report(index, "Creating unit default collections (2/2)")
    end
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
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr       = line.split("|").map(&:strip)
      collection_id = row_arr[0].to_i
      group_id      = row_arr[1].to_i

      progress.report(row_num, "Importing collection-community joins")

      UnitCollectionMembership.where(unit_id:       group_id,
                                     collection_id: collection_id,
                                     primary:       true).first_or_create!
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_collections_2_items(csv_pathname)
    @running = true
    LOGGER.debug("import_collections_2_items(): importing %s",
                 csv_pathname)
    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr               = line.split("|").map(&:strip)
      item_id               = row_arr[0].to_i
      collection_id         = row_arr[1].to_i
      primary_collection_id = row_arr[2].to_i

      progress.report(row_num, "Importing collection-item joins")
      begin
        CollectionItemMembership.where(collection_id: collection_id,
                                       item_id:       item_id,
                                       primary:       (collection_id == primary_collection_id)).first_or_create!
      rescue ActiveRecord::RecordInvalid
        # Either the item or the collection does not exist. Nothing we can do.
      end
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_communities(csv_pathname)
    @running = true

    # Create an institution in which to put them, if it does not already exist.
    institution = Institution.find_by_key("uiuc") ||
      Institution.where(name:   "Will get overwritten",
                        key:    "Will get overwritten",
                        org_dn: ShibbolethUser::UIUC_ORG_DN).first_or_create!

    LOGGER.debug("import_communities(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr      = line.split("|").map(&:strip)
      community_id = row_arr[0].to_i

      progress.report(row_num, "Importing communities")
      unit             = Unit.where(id: community_id).first_or_initialize
      unit.institution = institution
      unit.title     ||= "Temporary Title"
      elem_name  = row_arr[1]
      elem_name += ":#{row_arr[2]}" if row_arr[2].present?
      # Replace @@@@ with newline, strip leading and trailing quote,
      # and double quotes.
      string = row_arr[3]&.strip&.gsub("@@@@", "\n")&.gsub(/^"/, "")&.gsub(/"$/, "")&.gsub('""', '"')
      if string.present?
        case elem_name
        when "description"
          unit.introduction = string
        when "description:abstract"
          unit.short_description = string
        when "rights"
          unit.rights = string
        when "title"
          unit.title = string
        end
      end
      unit.save!
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
      handle_parts = row[1].split("/")
      suffix       = handle_parts.last
      handle       = nil

      progress.report(row_num, "Importing handles")

      begin
        case row[2].to_i
        when 4 # community
          unit       = Unit.find_by(id: row[3].to_i)
          if unit && !unit.handle
            handle = unit.build_handle(suffix: suffix)
          end
        when 3 # collection
          collection = Collection.find_by(id: row[3].to_i)
          if collection && !collection.handle
            handle = collection&.build_handle(suffix: suffix)
          end
        when 2 # item
          item       = Item.find_by(id: row[3].to_i)
          if item && !item.handle
            handle = item&.build_handle(suffix: suffix)
          end
        else
          # Getting here would be unexpected, but also unrecoverable
        end
        handle&.save!
      rescue ActiveRecord::RecordNotUnique
        # nothing we can do
      rescue ActiveRecord::RecordNotSaved => e
        raise e unless e.message.include?("Failed to remove the existing associated handle")
      end
    end
    Handle.set_suffix_start(Handle.order(suffix: :desc).limit(1).first.suffix + 1)
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

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr    = line.split("|").map(&:strip)
      item_id    = row_arr[4].to_i
      elem_name  = "#{row_arr[0]}:#{row_arr[1]}"
      elem_name += ":#{row_arr[2]}" if row_arr[2].present?
      reg_elem   = RegisteredElement.find_by_name(elem_name)
      string     = row_arr[3]&.strip&.gsub("@@@@", "\n")
      place      = row_arr[5].to_i
      next unless string.present?

      progress.report(row_num, "Importing item metadata (1/2)")
      begin
        AscribedElement.create!(registered_element: reg_elem,
                                item_id:            item_id,
                                string:             string,
                                position:           place)
      rescue ActiveRecord::RecordInvalid
        # This may be caused by either a nonexistent RegisteredElement, or a
        # nonexistent Item. Not much we can do in either case.
      rescue ActiveRecord::InvalidForeignKey
        # DSpace does not have a hard elements-items foreign key and there may
        # be some inconsistency, which we have not much choice but to ignore.
      end
    end
  ensure
    @running = false
  end

  ##
  # Must be run after {import_item_metadata}.
  #
  def process_embargoes
    @running = true
    count    = Item.count
    progress = Progress.new(count)
    Item.uncached do
      Item.find_each.with_index do |item, index|
        expires_at = item.element("dc:date:embargo")&.string&.strip
        if expires_at.present?
          begin
            expires_at = Time.parse(expires_at)
            if expires_at > Time.now
              # Embargoes without expiration are set to the year 10000 in
              # DSpace. But Elasticsearch can't handle years that far out, so
              # pull them in.
              if expires_at.year > 2500
                expires_at = expires_at.change(year: 2500)
                perpetual  = true
              else
                perpetual = false
              end
              case item.element("dc:description:terms")&.string
              when "U of I Only"
                group = UserGroup.find_by_key("uiuc")
              when "Limited"
                group = UserGroup.sysadmin
              else
                group = nil
              end
              embargo_reason = item.element("dc:description:reason")&.string
              groups = group ? [group] : []
              if item.embargoes.where(expires_at: expires_at).count < 1
                item.embargoes.build(download:    true,
                                     full_access: true,
                                     perpetual:   perpetual,
                                     expires_at:  expires_at,
                                     user_groups: groups,
                                     reason:      embargo_reason).save!
              end
            end
          rescue ArgumentError
          end
        end
        progress.report(index, "Processing item embargoes")
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

      row          = line.split("|").map(&:strip)
      id           = row[0].to_i
      submitter_id = row[1]
      submitting   = row[2] != "t"
      withdrawn    = row[3] == "t"
      discoverable = row[4] == "t"
      if withdrawn
        stage = Item::Stages::WITHDRAWN
      elsif submitting
        stage = Item::Stages::SUBMITTING
      else
        stage = Item::Stages::APPROVED
      end
      begin
        item = Item.where(id: id).first_or_create!(submitter_id: submitter_id,
                                                   stage:        stage,
                                                   discoverable: discoverable)
      rescue ActiveRecord::InvalidForeignKey
        item = Item.create!(id:           id,
                            submitter_id: nil,
                            stage:        stage,
                            discoverable: discoverable)
      end
      item.events.where(event_type:  Event::Type::CREATE).
        first_or_create!(after_changes: JSON.generate(item.as_change_hash),
                         description: "Item imported from DSpace.")
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

    line_count       = count_lines(csv_pathname)
    progress         = Progress.new(line_count)
    uiuc_institution = Institution.find_by_key("uiuc")

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr  = line.split("|").map(&:strip)
      name     = "#{row_arr[1]}:#{row_arr[2]}"
      name    += ":#{row_arr[3]}" if row_arr[3].present?

      progress.report(row_num, "Importing registered elements")
      begin
        RegisteredElement.where(id: row_arr[0]).first_or_create!(
          institution: uiuc_institution,
          name:        name,
          uri:         "http://example.org/#{name}",
          label:       "Label For #{name}",
          scope_note:  row_arr[4])
      rescue ActiveRecord::RecordInvalid
        # probably alrady imported
      end
    end
    update_pkey_sequence("registered_elements")
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_user_group_joins(csv_pathname)
    @running = true
    LOGGER.debug("import_user_group_joins(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row
      row_arr          = line.split("|").map(&:strip)
      group_id         = row_arr[0].to_i
      child_id         = row_arr[1].to_i
      next if group_id == 0 # skip the anonymous group
      unit_admin_id    = row_arr[2].to_i
      col_admin_id     = row_arr[3].to_i
      col_admin2_id    = row_arr[4].to_i
      col_submitter_id = row_arr[5].to_i

      begin
        if unit_admin_id > 0
          AdministratorGroup.where(user_group_id: child_id || group_id,
                                   unit_id:       unit_admin_id).first_or_create!
        elsif col_admin_id > 0
          ManagerGroup.where(user_group_id: child_id || group_id,
                             collection_id: col_admin_id).first_or_create!
        elsif col_admin2_id > 0
          ManagerGroup.where(user_group_id: child_id || group_id,
                             collection_id: col_admin2_id).first_or_create!
        elsif col_submitter_id > 0
          SubmitterGroup.where(user_group_id: child_id || group_id,
                               collection_id: col_submitter_id).first_or_create!
        end
      rescue ActiveRecord::RecordInvalid
        # nothing we can do
      end

      progress.report(row_num, "Importing user group joins")
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_user_groups(csv_pathname)
    @running = true
    LOGGER.debug("import_user_groups(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr  = line.split("|").map(&:strip)
      group_id = row_arr[0].to_i
      next if group_id == 0 # skip the anonymous group
      name     = row_arr[1]
      key      = name.downcase.
        gsub(" [automated]", ""). # trim off " [automated]"
        gsub(" - ", "_").         # replace dash space dash with underscore
        gsub(/[^a-z0-9\-_]/, "_"). # replace non-alphanumerics & dashes with underscore
        gsub(/_{2,}/, "_").       # replace multiple underscores with one
        gsub(/_$/, "")            # trim off trailing underscore
      next if name.blank?

      group = UserGroup.where(id: group_id).first_or_create!(name: name, key: key)
      # These are UIUC's attribute (department)-based groups. Their name is the
      # department name minus the "[automated]" suffix.
      if [2, 7, 8, 9, 41, 42, 43, 489, 490, 491, 492].include?(group_id)
        dept_name = name.gsub("[automated]", "").strip
        if group.departments.where(name: dept_name).count < 1
          group.departments.build(name: dept_name).save!
        end
      end

      progress.report(row_num, "Importing user groups")
    end
  ensure
    @running = false
  end

  ##
  # @param csv_pathname [String]
  #
  def import_user_groups_2_users(csv_pathname)
    @running = true
    LOGGER.debug("import_user_groups_2_users(): importing %s", csv_pathname)

    line_count = count_lines(csv_pathname)
    progress   = Progress.new(line_count)

    File.open(csv_pathname, "r").each_line.with_index do |line, row_num|
      next if row_num == 0 # skip header row

      row_arr  = line.split("|").map(&:strip)
      group_id = row_arr[0].to_i
      user_id  = row_arr[1].to_i
      begin
        group = UserGroup.find(group_id)
        unless group.user_ids.include?(user_id)
          group.user_ids << user_id
          group.save!
        end
      rescue ActiveRecord::RecordNotFound
        # nothing we can do
      end

      progress.report(row_num, "Importing user group-user joins")
    end
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
    progress   = Progress.new(line_count)

    # This technique is quite inefficient, but Postgres does not make pivot
    # queries easy...
    #
    # For step 1, we gather a set of hashes containing exported user
    # attributes--one hash per user.
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

    # In step 2, we create User objects corresponding to the hashes in the set.
    progress = Progress.new(users.length)
    users.each_with_index do |user_info, index|
      new_name = "#{user_info[:first_name]} #{user_info[:last_name]}"
      if new_name.present?
        begin
          user = User.find(user_info[:id])
          user.update!(name:  new_name,
                       phone: user_info[:phone])
        rescue ActiveRecord::RecordNotFound
          # nothing we can do
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
      # Some of the email addresses in the eperson table are invalid and some
      # are in "spam avoidance format," like "user at uiuc dot edu". We will
      # try to fix them.
      email = row[1].strip.
        gsub('"', "").
        gsub(/(\w+) at (\w+) dot (\w+)/, "\\1@\\2.\\3").
        downcase
      next if email.blank?
      email      += "@example.org" unless email.include?("@")
      email_parts = email.split("@")
      username    = email_parts[0]
      tld         = email.scan(/(\w+).(\w+)$/).last.join(".")
      begin
        if ::Configuration.instance.uofi_email_domains.include?(tld)
          ShibbolethUser.where(id: id).first_or_create!(
            uid:    email,
            email:  email,
            name:   username,
            org_dn: ShibbolethUser::UIUC_ORG_DN)
        elsif !LocalUser.find_by_email(email)
          user = LocalUser.create_manually(email:    email,
                                           password: SecureRandom.hex)
          # Many items were bulk-imported into IDEALS-DSpace under this email.
          user.update!(name: "Seth Robbins") if email == "robbins.sd@gmail.com"
        end
      rescue ActiveRecord::RecordInvalid => e
        raise "Email is invalid: #{email}" if e.message.include?("Email is invalid")
        raise e unless e.message.include?("Email has already been taken")
      rescue ActiveRecord::RecordNotUnique
        # nothing we can do
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
