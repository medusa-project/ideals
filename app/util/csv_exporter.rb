##
# Exports [Item]s in CSV format.
#
# See [CsvImporter] for documentation of the CSV format.
#
class CsvExporter

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
  def export_collection(collection, elements: nil)
    elements     ||= collection.effective_metadata_profile.elements.map(&:name)
    collection_ids = [collection.id] + collection.all_children.pluck(:id)

    sql = select_clause(elements) +
      from_clause +
      "LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id " +
      "WHERE cim.collection_id IN (#{collection_ids.join(", ")}) " +
      order_clause
    results = ActiveRecord::Base.connection.exec_query(sql)
    to_csv(elements, results)
  end

  ##
  # Exports all items contained in any of a [Unit]'s collections.
  #
  # @param unit [Unit]
  # @param elements [Enumerable<String>] Elements to include. If omitted, all
  #                 of the elements in the {MetadataProfile#default default
  #                 metadata profile} are included.
  # @return [String] CSV string.
  #
  def export_unit(unit, elements: nil)
    elements     ||= MetadataProfile.default.elements.map(&:name)
    collection_ids = unit.collections.pluck(:id)

    sql = select_clause(elements) +
      from_clause +
      "LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id " +
      "WHERE cim.collection_id IN (#{collection_ids.join(", ")}) " +
      order_clause
    results = ActiveRecord::Base.connection.exec_query(sql)
    to_csv(elements, results)
  end


  private

  ##
  # @param elements [Enumerable<String>]
  # @return [String]
  #
  def select_clause(elements)
    columns = []
    elements.each_with_index do |element, index|
      columns << "array_to_string(
        array(
          SELECT replace(replace(coalesce(ae.string, '') || '&&<' || coalesce(ae.uri, '') || '>', '&&<>', ''), '||&&', '')
          FROM ascribed_elements ae
          LEFT JOIN registered_elements re ON ae.registered_element_id = re.id
          WHERE ae.item_id = i.id
            AND re.name = '#{element}'
            AND (length(ae.string) > 0 OR length(ae.uri) > 0)
          ), '||') AS c_#{index}\n"
    end
    "SELECT i.id,\n" + columns.join(",") + " "
  end

  def from_clause
    "FROM items i "
  end

  def order_clause
    "ORDER BY i.id;"
  end

  def to_csv(elements, results)
    CSV.generate(headers: true) do |csv|
      csv << ["id"] + elements
      results.each do |row|
        csv << row.values
      end
    end
  end

end