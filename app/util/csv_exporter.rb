# frozen_string_literal: true

##
# Exports {Item}s in CSV format.
#
# See {CsvImporter} for documentation of the CSV format.
#
class CsvExporter

  ##
  # Exports all items from all of the given units and collections, including
  # child units and collections.
  #
  # All provided units and collections must be in the same institution.
  #
  # @param units [Enumerable<Unit>]
  # @param collections [Enumerable<Collection>]
  # @param elements [Enumerable<String>] Elements to include. If omitted, all
  #                 of the elements in the
  #                 {Institution#default_metadata_profile default metadata
  #                 profile of an institution associated with one of the units
  #                 or collections} are included.
  # @return [String] CSV string.
  #
  def export(units: [], collections: [], elements: [])
    if units.empty? && collections.empty?
      raise ArgumentError, "No units or collections specified."
    end
    # Add all children to the units bucket.
    all_units = Set.new
    units.each do |unit|
      all_units << unit
      all_units += unit.all_children
    end
    # Compile a list of collection IDs from which to export items.
    collection_ids = Set.new
    all_units.each do |unit|
      collection_ids += unit.collections.pluck(:id)
    end
    collections.each do |collection|
      collection_ids << collection.id
      collection_ids += collection.all_child_ids
    end
    # Compile a list of elements to include.
    if elements.empty?
      profile  = collections.first&.effective_metadata_profile ||
        units.first&.institution&.default_metadata_profile
      elements = profile.elements.map(&:name)
    end

    # Only items that belong to any of these collections primarily are
    # included. Otherwise, they may be subject to different metadata profiles
    # which could cause their metadata to not align with the columns in the
    # CSV, resulting in metadata loss.
    where_clause = collection_ids.any? ?
                     "WHERE cim.collection_id IN (#{collection_ids.join(", ")}) " :
                     "WHERE 1 = 2 "

    # SQL is used for efficiency here--ActiveRecord would be super slow.
    sql = select_clause(elements) +
      from_clause +
      join_clauses +
      where_clause +
      order_clause
    results = ActiveRecord::Base.connection.exec_query(sql)
    to_csv(elements, results)
  end

  ##
  # Exports items from a collection and all of its child collections.
  #
  # @param collection [Collection]
  # @param elements [Enumerable<String>] Elements to include. If omitted, all
  #                 of the elements in the collection's
  #                 {Collection#effective_metadata_profile effective metadata
  #                 profile} are included.
  # @return [String] CSV string.
  #
  def export_collection(collection, elements: [])
    if elements.empty?
      elements = collection.effective_metadata_profile.elements.map(&:name)
    end
    export(collections: [collection], elements: elements)
  end

  ##
  # Exports the given items.
  #
  # @param item_ids [Enumerable<Integer>]
  # @param elements [Enumerable<String>]
  # @return [String] CSV string.
  #
  def export_items(item_ids:, elements:)
    raise ArgumentError, "No item IDs provided." if item_ids.empty?
    raise ArgumentError, "No elements provided." if elements.empty?
    sql = select_clause(elements) +
      from_clause +
      join_clauses +
      "WHERE items.id IN (#{item_ids.join(",")}) AND cim.primary = true " +
      order_clause
    results = ActiveRecord::Base.connection.exec_query(sql)
    to_csv(elements, results)
  end

  ##
  # Exports all items contained in any of a {Unit}'s collections.
  #
  # @param unit [Unit]
  # @param elements [Enumerable<String>] Elements to include. If omitted, all
  #                 of the elements in the
  #                 {Institution#default_metadata_profile default metadata
  #                 profile of an institution associated with one of the units
  #                 or collections} are included.
  # @return [String] CSV string.
  #
  def export_unit(unit, elements: [])
    export(units: [unit], elements: elements)
  end


  private

  ##
  # @param elements [Enumerable<String>]
  # @return [String]
  #
  def select_clause(elements)
    columns = ["items.id", "item_handles.suffix AS item_handle"]
    # collection_handles column
    columns << "array_to_string(
       array(
         SELECT h.suffix AS suffix
         FROM handles h
         LEFT JOIN collection_item_memberships cim ON cim.item_id = items.id
         WHERE cim.item_id = items.id
         AND h.collection_id = cim.collection_id
         ORDER BY cim.primary DESC NULLS LAST
       ), '||') AS collection_handles\n"
    # files column
    columns << "array_to_string(
       array(
         SELECT b.filename
         FROM bitstreams b
         WHERE b.item_id = items.id
         ORDER BY b.filename
       ), '||') AS filenames\n"
    # file_descriptions column
    columns << "array_to_string(
       array(
         SELECT b.description
         FROM bitstreams b
         WHERE b.item_id = items.id
         ORDER BY b.filename
       ), '||') AS file_descriptions\n"
    # embargo_types column
    columns << "array_to_string(
       array(
         SELECT e.kind
         FROM embargoes e
         WHERE e.item_id = items.id
         ORDER BY e.expires_at
       ), '||') AS embargo_types\n"
    # embargo_expirations column
    columns << "array_to_string(
       array(
         SELECT e.expires_at
         FROM embargoes e
         WHERE e.item_id = items.id
         ORDER BY e.expires_at
       ), '||') AS embargo_expirations\n"
    # embargo_exempt_user_groups column
    columns << "array_to_string(
       array(
         SELECT ug.key
         FROM embargoes e
         LEFT JOIN embargoes_user_groups eug ON e.id = eug.embargo_id
         LEFT JOIN user_groups ug on eug.user_group_id = ug.id
         WHERE e.item_id = items.id
         ORDER BY e.expires_at
       ), '||') AS embargo_exempt_user_groups\n"
    # embargo_reasons column
    columns << "array_to_string(
       array(
         SELECT e.reason
         FROM embargoes e
         WHERE e.item_id = items.id
         ORDER BY e.expires_at
       ), '||') AS embargo_reason\n"
    # Element columns
    elements.each_with_index do |element, index|
      columns << "array_to_string(
        array(
          SELECT replace(replace(ae.string || '&&<' || coalesce(ae.uri, '') || '>', '&&<>', ''), '||&&', '')
          FROM ascribed_elements ae
          LEFT JOIN registered_elements re ON ae.registered_element_id = re.id
          WHERE ae.item_id = items.id
            AND re.name = '#{element}'
            AND (length(ae.string) > 0 OR length(ae.uri) > 0)
          ), '||') AS e_#{index}\n"
    end
    "SELECT " + columns.join(", ") + " "
  end

  def from_clause
    "FROM items "
  end

  def join_clauses
    "LEFT JOIN handles item_handles ON item_handles.item_id = items.id\n" +
    "LEFT JOIN collection_item_memberships cim ON cim.item_id = items.id "
  end

  def order_clause
    "ORDER BY items.id;"
  end

  def to_csv(elements, results)
    CSV.generate(headers: true, quote_empty: false) do |csv|
      csv << CsvImporter::REQUIRED_COLUMNS + elements
      results.each do |row|
        csv << row.values
      end
    end
  end

end
