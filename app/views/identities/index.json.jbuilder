# frozen_string_literal: true

json.array! @identities, partial: "identities/identity", as: :identity
