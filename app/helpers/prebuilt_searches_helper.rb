# frozen_string_literal: true

module PrebuiltSearchesHelper

  def prebuilt_search_redirect_path(search)
    search_path + search.url_query
  end

  def prebuilt_search_redirect_url(search)
    search.institution.scope_url + prebuilt_search_redirect_path(search)
  end

end
