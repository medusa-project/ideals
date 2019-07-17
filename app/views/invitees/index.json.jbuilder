# frozen_string_literal: true

json.array! @invitees, partial: "invitees/invitee", as: :invitee
