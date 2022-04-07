# frozen_string_literal: true

class HandlesController < ApplicationController

  ##
  # Permanently redirects URLs from DSpace to their modern counterparts.
  #
  # Responds to `/handle/:prefix/:suffix`.
  #
  def redirect
    if params[:prefix] != ::Configuration.instance.handles[:prefix].to_s
      render plain: "Unrecognized handle prefix", status: 404 and return
    end
    handle = Handle.find_by_suffix(params[:suffix])
    raise ActiveRecord::RecordNotFound unless handle

    redirect_to (handle.item || handle.collection || handle.unit),
                status: :moved_permanently
  end

end