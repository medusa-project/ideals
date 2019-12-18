# frozen_string_literal: true

json.array! @resources, partial: "items/item", as: :item
