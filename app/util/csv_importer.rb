##
# Imports [Item]s in CSV format.
#
# # CSV Format
#
# ## Header row
#
# The header row defines the metadata values contained in succeeding rows.
# The first column, `id`, refers to an item's internal database ID. The other
# columns contain metadata element values, and are optional.
#
# ## Non-header rows
#
# Each row corresponds to a particular item, with each cell specifying a
# [RegisteredElement metadata element] value. Multiple values are separated
# with a double pipe (`||`).
#
# # Element processing
#
# Existing values can be edited, and additional values can be added using the
# double pipe.
#
# During an import, the metadata for the field/item combination represented by
# each cell is changed to reflect the contents of the CSV. Note that this means
# that if there are multiple values for a given field and a change is only
# needed for some of the values, the unchanged values must still appear in the
# CSV or they will be deleted.
#
# If an element does not appear as a column in the CSV, metadata values of that
# element are ignored and unaffected by the editing process.
#
# Leaving a column intact but with no value will cause that element to be
# deleted.
#
# # Metadata-only items
#
# To create a new item, enter a plus sign (`+`) in the `id` column.
#
class CsvImporter

  MULTI_VALUE_DELIMITER = "||"
  NEW_ITEM_INDICATOR    = "+"

  ##
  # Imports from a CSV string.
  #
  # @param csv [String] CSV string.
  # @param submitter [User]
  # @param primary_collection [Collection] Collection to import new items into.
  # @param imported_items [Array] For each imported item, whether created or
  #                               updated, a hash containing `item_id` and
  #                               `handle` keys will be added.
  # @param print_progress [Boolean] Whether to print progress updates to
  #                                 stdout.
  # @param task [Task] Optional; supply to receive progress updates.
  # @return [void]
  #
  def import(csv:,
             submitter:,
             primary_collection:,
             imported_items: [],
             print_progress: false,
             task:           nil)
    rows     = CSV.parse(csv)
    num_rows = rows.length - 1 # exclude header
    progress = print_progress ? Progress.new(num_rows) : nil
    # Work inside a transaction to avoid any incompletely created items.
    Import.transaction do
      begin
        rows[1..].each_with_index do |row, row_index|
          status_text = "Importing #{num_rows} items from CSV"
          progress&.report(row_index, status_text)
          task&.progress(row_index / (rows.length - 1).to_f,
                         status_text: status_text)
          item_id = row[0].strip
          if item_id == NEW_ITEM_INDICATOR
            item = create_item(submitter:          submitter,
                               primary_collection: primary_collection,
                               header_row:         rows[0],
                               columns:            row[1..])
          else
            item = update_item(item_id:    item_id,
                               submitter:  submitter,
                               header_row: rows[0],
                               columns:    row[1..])
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
  # Imports from an [Import] instance corresponding to a CSV file in the
  # application S3 bucket.
  #
  # @param import [Import]
  # @param submitter [User]
  # @param task [Task] Optional; supply to receive progress updates.
  # @return [void]
  #
  def import_from_s3(import, submitter, task: nil)
    object_keys    = import.object_keys
    csv_object_key = object_keys.first
    imported_items = []
    import.update!(kind:           Import::Kind::CSV,
                   files:          [csv_object_key],
                   status:         Import::Status::RUNNING,
                   imported_items: imported_items)

    csv = PersistentStore.instance.get_object(key: csv_object_key).read
    import(csv:                csv,
           submitter:          submitter,
           primary_collection: import.collection,
           imported_items:     imported_items,
           task:               task)
  rescue => e
    import.update!(status:             Import::Status::FAILED,
                   last_error_message: e.message)
    task&.fail(detail:    e.message,
               backtrace: e.backtrace)
    raise e
  else
    import.update!(status:             Import::Status::SUCCEEDED,
                   imported_items:     imported_items,
                   last_error_message: nil)
    task&.succeed
  end


  private

  def create_item(submitter:, primary_collection:, header_row:, columns:)
    item = CreateItemCommand.new(submitter:          submitter,
                                 institution:        primary_collection.institution,
                                 primary_collection: primary_collection,
                                 stage:              Item::Stages::SUBMITTED,
                                 event_description:  "Item imported from CSV.").execute
    item.assign_handle
    ascribe_metadata(item:       item,
                     header_row: header_row,
                     columns:    columns)
    item.save!
    item
  end

  def update_item(item_id:, submitter:, header_row:, columns:)
    item = Item.find(item_id)
    UpdateItemCommand.new(item:        item,
                          user:        submitter,
                          description: "Updated via CSV").execute do
      ascribe_metadata(item:       item,
                       header_row: header_row,
                       columns:    columns)
      item.save!
    end
    item
  end

  def ascribe_metadata(item:, header_row:, columns:)
    columns.each_with_index do |cell_value, column_index|
      column_index += 1
      element_name  = header_row[column_index]
      item.elements.select{ |e| e.name == element_name }.each(&:destroy)
      values = cell_value.split(MULTI_VALUE_DELIMITER)
      values.select(&:present?).each_with_index do |value, value_index|
        reg_el = RegisteredElement.where(name:        element_name,
                                         institution: item.institution).limit(1).first
        unless reg_el
          raise ArgumentError, "Element not present in registry: #{element_name}"
        end
        item.elements.build(registered_element: reg_el,
                            string:             value.strip,
                            position:           value_index + 1)
      end
    end
  end

end
