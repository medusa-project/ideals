class ResourceType
  ResourceTypeInfo = Struct.new(:klass_name, :code)
  BITSTREAM = 0
  ITEM = 2
  COLLECTION = 3
  UNIT = 4
  HASH = {
      BITSTREAM => 'Bitstream',
      ITEM => 'Item',
      COLLECTION => 'Collection',
      UNIT => 'Unit'
  }
end