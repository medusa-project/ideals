json.array! @units do |unit|
  json.class          unit.class.to_s
  json.id             unit.id
  json.title          unit.title
  json.uri            unit_url(unit)
  json.numChildren    unit.units.length
  json.numCollections unit.all_collections.reject(&:unit_default).length
end
