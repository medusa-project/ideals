module PrebuiltSearchesHelper

  def prebuilt_search_redirect_path(search)
    items_path + search.url_query
  end

end
