json.array! @units do |unit|
  json.class          unit.class.to_s
  json.id             unit.id
  json.title          unit.title
  json.uri            unit_url(unit)
  json.numChildren    unit.units.length
  json.numCollections unit.unit_collection_memberships.count
end
