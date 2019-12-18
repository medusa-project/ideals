# frozen_string_literal: true

json.array! @resources, partial: "collections/collection", as: :collection
