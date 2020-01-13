class ResourceType
  ResourceTypeInfo = Struct.new(:klass_name, :code)
  BITSTREAM = 0
  ITEM = 2
  COLLECTION = 3
  UNIT = 4
  HASH = {0 => 'Bitstream', 2 => 'Item', 3 => 'Collection', 4 => 'Unit'}
  Array = [ResourceTypeInfo.new('Bitstream', 0),
           ResourceTypeInfo.new('Item', 2),
           ResourceTypeInfo.new('Collection', 3),
           ResourceTypeInfo.new('Unit', 4)]
end