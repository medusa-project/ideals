json.extract! collection_group, :id, :title, :group_id, :parent_group_id, :group_type, :created_at, :updated_at
json.url collection_group_url(collection_group, format: :json)
