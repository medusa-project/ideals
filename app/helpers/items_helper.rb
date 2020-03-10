module ItemsHelper

  ##
  # @param selected_collection [Collection] Optional.
  # @return [ActiveSupport::SafeBuffer,Enumerable<String>] Return value of
  #         {options_for_select}.
  #
  def deposit_collection_options_for_select(selected_collection = nil)
    collections = current_user.submitting_collections
    options = collections.map{ |c| [raw(c.title), c.id] }
    options_for_select(options, selected_collection&.id)
  end

end