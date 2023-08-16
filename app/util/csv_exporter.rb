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
    # Compile a list of collection IDs from which to export items.
    collection_ids = Set.new
    units.each do |unit|
      collection_ids += unit.collections.pluck(:id)
    end
    collections.each do |collection|
      collection_ids << collection.id
      collection_ids += collection.all_children.pluck(:id)
    end
    # Compile a list of elements to include.
    if elements.empty?
      profile  = collections.first&.effective_metadata_profile ||
        units.first&.effective_metadata_profile
      elements = profile.elements.map(&:name)
    end

    where_clause = collection_ids.any? ?
                     "WHERE cim.collection_id IN (#{collection_ids.join(", ")}) " :
                     "WHERE 1 = 2 "

    # SQL is used for efficiency here--ActiveRecord would be super slow.
    sql = select_clause(elements) +
      from_clause +
      "LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id " +
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
    columns = ["i.id"]
    # files column
    columns << "array_to_string(
       array(
         SELECT b.filename
         FROM bitstreams b
         WHERE b.item_id = i.id
         ORDER BY b.filename
       ), '||') AS filenames\n"
    # file_descriptions column
    columns << "array_to_string(
       array(
         SELECT b.description
         FROM bitstreams b
         WHERE b.item_id = i.id
         ORDER BY b.filename
       ), '||') AS file_descriptions\n"
    # embargo_types column
    columns << "array_to_string(
       array(
         SELECT e.kind
         FROM embargoes e
         WHERE e.item_id = i.id
         ORDER BY e.expires_at
       ), '||') AS embargo_types\n"
    # embargo_expirations column
    columns << "array_to_string(
       array(
         SELECT e.expires_at
         FROM embargoes e
         WHERE e.item_id = i.id
         ORDER BY e.expires_at
       ), '||') AS embargo_expirations\n"
    # embargo_exempt_user_groups column
    columns << "array_to_string(
       array(
         SELECT ug.key
         FROM embargoes e
         LEFT JOIN embargoes_user_groups eug ON e.id = eug.embargo_id
         LEFT JOIN user_groups ug on eug.user_group_id = ug.id
         WHERE e.item_id = i.id
         ORDER BY e.expires_at
       ), '||') AS embargo_exempt_user_groups\n"
    # embargo_reasons column
    columns << "array_to_string(
       array(
         SELECT e.reason
         FROM embargoes e
         WHERE e.item_id = i.id
         ORDER BY e.expires_at
       ), '||') AS embargo_reason\n"
    # Element columns
    elements.each_with_index do |element, index|
      columns << "array_to_string(
        array(
          SELECT replace(replace(ae.string || '&&<' || coalesce(ae.uri, '') || '>', '&&<>', ''), '||&&', '')
          FROM ascribed_elements ae
          LEFT JOIN registered_elements re ON ae.registered_element_id = re.id
          WHERE ae.item_id = i.id
            AND re.name = '#{element}'
            AND (length(ae.string) > 0 OR length(ae.uri) > 0)
          ), '||') AS e_#{index}\n"
    end
    "SELECT " + columns.join(", ") + " "
  end

  def from_clause
    "FROM items i "
  end

  def order_clause
    "ORDER BY i.id;"
  end

  def to_csv(elements, results)
    CSV.generate(headers: true) do |csv|
      csv << CsvImporter::REQUIRED_COLUMNS + elements
      results.each do |row|
        csv << row.values
      end
    end
  end

end