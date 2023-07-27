# frozen_string_literal: true

##
# Imports {Item}s in CSV format.
#
# # Import types
#
# Two main types of content are supported: standalone files, and packages.
# This class supports both types.
#
# ## Standalone files
#
# The CSV file format is documented below. The primary difference between
# standalone files and packages is that there is no way to attach {Bitstream}s
# a.k.a. files to items when importing a CSV file alone. But standalone CSV
# files are more convenient for any kind of operation that doesn't involve
# adding bitstreams/files to items.
#
# ## Packages
#
# The package format is a superset of the file format. A CSV file (in its
# standard format) is present within the root directory of a package, which is
# a directory or folder. It may contain other files in the same folder, or
# subfolders, that can be referenced from within the CSV file.
#
# # CSV File Format Specification
#
# ## Header row
#
# The first column, `id`, refers to an item's internal database ID. The next
# several columns refer to various system-level item properties. The remaining
# columns correspond to the elements in the effective {MetadataProfile} of the
# collection that apply to the item.
#
# All columns are required except metadata columns. When a metadata column is
# missing, the corresponding metadata elements of the items in the CSV file
# will be left unchanged. For new items in the CSV file, a missing metadata
# column may be an error depending on whether it is required or not.
#
# ## Non-header rows
#
# Each row corresponds to a particular item, and each cell corresponds to a
# property or {AscribedElement metadata element} value of that item. For item
# updates, the first cell contains the item's database ID. To create new items,
# a plus sign (`+`) must be entered into the first cell. An empty first cell is
# always invalid.
#
# The next group of cells correspond to various system properties of the item:
#
# * `files`                      Names of all files attached to an item. For
#                                uploads, this may be a path relative to a
#                                package root in which the CSV resides.
# * `file_descriptions`          File description strings.
# * `embargo_types`              One of the {Embargo::Kind} constant values.
# * `embargo_expirations`        Dates in `YYYY-MM-DD` format, or blank values
#                                to indicate no expiration.
# * `embargo_exempt_user_groups` Comma-separated user group keys.
# * `embargo_reasons`            Embargo reason strings.
#
# The last group of cells contain metadata element values.
#
# Most cells support multiple values by concatenating them together with a
# double pipe (`||`).
#
# ### Files
#
# Files can be uploaded along with items by referencing them within the
# `filenames` column. Multiple files can be referenced from the same cell by
# concatenating them together with a double pipe (`||`). The files may exist in
# the same path as the CSV file, or within subdirectories. In this case, their
# full path relative to the CSV file's directory would be included in the
# `filenames` column.
#
# Files can also be added to existing items, but existing items' files cannot
# be updated. For example, an item that has a file named `document.pdf` can
# have a `document2.pdf` added to it; but not another `document.pdf`.
#
# ### File descriptions
#
# Files may optionally have descriptions appended to them. These must be
# entered in the same order as the filenames in the `filenames` column. Like
# the filenames, multiple descriptions must be concatenated together with a
# double pipe (`||`). If there are three files, and only the first and third
# are to receive descriptions, then the cell value would be:
#
# `First file description||||Third file description`
#
# (The space between the double pipes where the second description would go is
# empty.)
#
# ## Element processing
#
# Existing values can be edited, and additional values for the same element can
# be added by concatenating them together with a double pipe (`||`). If an
# element does not appear as a column in the CSV, any existing values of that
# element are left unchanged. Leaving a column intact but with no value will
# cause that element to be deleted.
#
# During an import, the metadata for the field/item combination represented by
# each cell is changed to reflect the contents of the CSV. Note that this means
# that if there are multiple values for a given field and a change is only
# needed for some of the values, the unchanged values must still appear in the
# CSV or they will be deleted.
#
# # CSV Package Format Specification
#
# A CSV package is a directory/folder consisting of a single CSV file at the
# root level of the package and any number of other files referenced from the
# `files` column cells in the CSV file. These files may reside in the same
# folder as the CSV file itself, or in subfolders. (To support same-named files
# attached to different items, subfolders will be required.)
#
class CsvImporter

  MULTI_VALUE_DELIMITER  = "||"
  NEW_ITEM_INDICATOR     = "+"
  REQUIRED_COLUMNS       = %w[id files file_descriptions embargo_types
                              embargo_expirations embargo_exempt_user_groups
                              embargo_reasons]

  ##
  # Imports items from a CSV string.
  #
  # @param csv [String] CSV string.
  # @param object_keys [Enumerable<String>] Keys of objects in the application
  #                                         bucket that are referenced in the
  #                                         CSV's `files` column.
  # @param submitter [User]
  # @param primary_collection [Collection] Collection to import new items into.
  # @param imported_items [Array<Hash>] For each imported item, whether created
  #                                     or updated, a hash containing
  #                                     `:item_id` and `:handle` keys will be
  #                                     added.
  # @param print_progress [Boolean] Whether to print progress updates to
  #                                 stdout.
  # @return [void]
  #
  def import(csv:,
             object_keys: [],
             submitter:,
             primary_collection:,
             imported_items: [],
             print_progress: false,
             task:           nil)
    rows     = CSV.parse(csv)
    num_rows = rows.length - 1 # exclude header
    progress = print_progress ? Progress.new(num_rows) : nil
    # Work inside a transaction to avoid any incompletely created items. If
    # any items fail, we want the whole import to fail.
    Import.transaction do
      begin
        validate_header(row: rows[0],
                        submission_profile: primary_collection.effective_submission_profile)
        rows[1..].each_with_index do |row, row_index|
          status_text = "Importing #{num_rows} items from CSV"
          progress&.report(row_index, status_text)
          task&.progress(row_index / (rows.length - 1).to_f,
                         status_text: status_text)
          # Create or update the item.
          item_id = row[REQUIRED_COLUMNS.index("id")]&.strip
          raise ArgumentError, "Missing item ID" if item_id.blank?
          if item_id == NEW_ITEM_INDICATOR
            item = create_item(submitter:          submitter,
                               primary_collection: primary_collection,
                               element_names:      rows[0][REQUIRED_COLUMNS.length..],
                               row:                row,
                               import_object_keys: object_keys)
          else
            item = Item.find(item_id)
            item = update_item(item:               item,
                               submitter:          submitter,
                               element_names:      rows[0][REQUIRED_COLUMNS.length..],
                               row:                row,
                               import_object_keys: object_keys)
          end
          imported_items << {
            item_id: item.id,
            handle:  item.handle&.handle
          }
        end
      rescue => e
        task&.fail(backtrace: e.backtrace,
                   detail:    e.message)
        raise e
      else
        task&.succeed
      end
    end
  end

  ##
  # Imports from an {Import} instance corresponding to either a CSV file or CSV
  # package in the application S3 bucket.
  #
  # @param import [Import]
  # @param submitter [User]
  # @return [void]
  #
  def import_from_s3(import, submitter)
    # Find the CSV file.
    object_keys      = import.object_keys
    root_object_keys = object_keys.select{ |k| k.split("/").length == object_keys.map{ |kl| kl.split("/").length }.sort.first }
    csv_object_key   = root_object_keys.find{ |k| k.downcase.end_with?(".csv") }
    imported_items   = []
    import.update!(format:         Import::Format::CSV_FILE,
                   files:          [csv_object_key],
                   imported_items: imported_items)
    import.task&.update!(status: Task::Status::RUNNING)

    csv = PersistentStore.instance.get_object(key: csv_object_key).read
    import(csv:                csv,
           object_keys:        object_keys,
           submitter:          submitter,
           primary_collection: import.collection,
           imported_items:     imported_items,
           task:               import.task)
  rescue => e
    import.task&.fail(detail:    e.message,
                      backtrace: e.backtrace)
    raise e
  else
    import.update!(imported_items: imported_items)
    import.task&.succeed
  end


  private

  def create_item(submitter:,
                  primary_collection:,
                  element_names:,
                  row:,
                  import_object_keys:)
    item = CreateItemCommand.new(submitter:          submitter,
                                 institution:        primary_collection.institution,
                                 primary_collection: primary_collection,
                                 stage:              Item::Stages::APPROVED,
                                 event_description:  "Item imported from CSV.").execute
    item.assign_handle
    associate_bitstreams(item:               item,
                         row:                row,
                         import_object_keys: import_object_keys)
    ascribe_metadata(item:               item,
                     submission_profile: primary_collection.effective_submission_profile,
                     column_names:       element_names,
                     column_values:      row[REQUIRED_COLUMNS.length..])
    associate_embargoes(item: item, row: row)
    item.save!
    item
  end

  def update_item(item:,
                  submitter:,
                  element_names:,
                  row:,
                  import_object_keys:)
    UpdateItemCommand.new(item:        item,
                          user:        submitter,
                          description: "Updated via CSV").execute do
      associate_bitstreams(item:               item,
                           row:                row,
                           import_object_keys: import_object_keys)
      ascribe_metadata(item:               item,
                       submission_profile: item.effective_primary_collection.effective_submission_profile,
                       column_names:       element_names,
                       column_values:      row[REQUIRED_COLUMNS.length..])
      associate_embargoes(item: item,
                          row:  row)
      item.save!
    end
    item
  end

  def ascribe_metadata(item:,
                       submission_profile:,
                       column_names:,
                       column_values:)
    reg_elements      = RegisteredElement.where(institution: item.institution)
    required_elements = submission_profile.elements.select(&:required).map(&:name)
    column_values.each_with_index do |cell_string, column_index|
      column_element = column_names[column_index]
      item.elements.select{ |e| e.name == column_element }.each(&:delete)
      if cell_string.present?
        reg_el = reg_elements.find{ |e| e.name == column_element }
        unless reg_el
          raise ArgumentError, "Element not present in registry: #{column_element}"
        end
        cell_values = cell_string.split(MULTI_VALUE_DELIMITER)
        cell_values.select(&:present?).each_with_index do |cell_value, value_index|
          AscribedElement.create!(item:               item,
                                  registered_element: reg_el,
                                  string:             cell_value.strip,
                                  position:           value_index + 1)
        end
      elsif required_elements.include?(column_element)
        raise ArgumentError, "Item #{item.id} has a blank #{column_element} "\
                             "cell, but a value in this cell is required by "\
                             "the submission profile."
      end
    end
    # TODO: remove this when confident
    item.reload
    if !item.element(required_elements.first)
      raise "Missing a #{required_elements.first} element. This is a bug "\
            "that the developer thought was fixed, but apparently not. Please "\
            "report this bug, and also, retry your import. (It only fails "\
            "sporadically.)"
    end
    # end remove
  end

  ##
  # @param item [Item]
  # @param row [Array<String>]
  # @param import_object_keys [Array<String>] Keys of files to import,
  #                                           corresponding to `files`.
  #
  def associate_bitstreams(item:,
                           row:,
                           import_object_keys:)
    file_rel_paths    = row[REQUIRED_COLUMNS.index("files")]&.split(MULTI_VALUE_DELIMITER)
    file_descriptions = row[REQUIRED_COLUMNS.index("file_descriptions")]&.split(MULTI_VALUE_DELIMITER)
    primary           = true
    bundle_position   = 0
    file_rel_paths&.each_with_index do |rel_path, file_index|
      filename = rel_path.split("/").last
      # Does the item already have a file with this name? If so, we will
      # skip it.
      unless item.bitstreams.find{ |b| b.filename == filename }
        # Was this file actually uploaded, i.e. does it exist in the bucket?
        # If so, we will copy it into its permanent location within the bucket,
        # and create a Bitstream to represent it. If not, we will skip it.
        upload_key = import_object_keys.find{ |k| k.end_with?(rel_path) }
        if upload_key
          store         = PersistentStore.instance
          permanent_key = Bitstream.permanent_key(institution_key: item.institution.key,
                                                  item_id:         item.id,
                                                  filename:        filename)
          Bitstream.create!(item:            item,
                            permanent_key:   permanent_key,
                            filename:        filename,
                            bundle:          Bitstream::Bundle::CONTENT,
                            bundle_position: bundle_position,
                            primary:         primary,
                            description:     file_descriptions ? file_descriptions[file_index] : nil,
                            length:          store.object_length(key: upload_key))
          store.copy_object(source_key: upload_key,
                            target_key: permanent_key)
          primary          = false
          bundle_position += 1
        end
      end
    end
  end

  def associate_embargoes(item:, row:)
    types              = row[REQUIRED_COLUMNS.index("embargo_types")]&.split(MULTI_VALUE_DELIMITER)
    expirations        = row[REQUIRED_COLUMNS.index("embargo_expirations")]&.split(MULTI_VALUE_DELIMITER)
    exempt_user_groups = row[REQUIRED_COLUMNS.index("embargo_exempt_user_groups")]&.split(MULTI_VALUE_DELIMITER)
    reasons            = row[REQUIRED_COLUMNS.index("embargo_reasons")]&.split(MULTI_VALUE_DELIMITER)
    return unless types&.any? || expirations&.any? ||
      reasons&.any?
    if types.length != expirations.length ||
      expirations.length != reasons.length
      raise ArgumentError, "Missing an embargo column value. Ensure that " +
        "there are equal numbers of values (separated by " +
        "#{MULTI_VALUE_DELIMITER}) in all embargo-related columns."
    end
    item.embargoes.destroy_all
    types.each_with_index do |type, index|
      embargo = Embargo.new(item:      item,
                            kind:      type,
                            perpetual: false,
                            reason:    reasons[index])
      if expirations[index].present?
        embargo.expires_at = Time.parse(expirations[index])
      else
        embargo.perpetual = true
      end
      # Add user groups
      exempt_user_groups[index]&.split(",")&.select(&:present?)&.each do |key|
        embargo.user_groups << UserGroup.find_by_key(key)
      end
      embargo.save!
    end
  end

  ##
  # @param row [Hash<String>]
  # @param submission_profile [SubmissionProfile]
  #
  def validate_header(row:, submission_profile:)
    required_elements = submission_profile.elements.select(&:required).map(&:name)
    missing_elements  = required_elements - row
    if missing_elements.any?
      raise ArgumentError, "The following elements are required by the "\
                           "collection's effective submission profile, but "\
                           "are missing columns in the CSV: #{missing_elements.join(", ")}"
    end
    REQUIRED_COLUMNS.each_with_index do |column, index|
      if row[index] != column
        raise ArgumentError, "Missing #{column} column"
      end
    end
  end

end
