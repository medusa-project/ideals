class ModelUtils

  ##
  # Compares two hashes of key-value pairs. The result is an array of hashes
  # with `:name`, `:before_value`, `:after_value`, and `:op` keys. The value
  # of the `:op` key may be `:added`, `:changed`, or `:removed`.
  #
  # The result contains one hash per unique key in the union of keys in the
  # given hashes whose values have been either added, changed, or removed.
  # Unchanged key-value pairs are omitted.
  #
  # @param model1 [Hash] Hash of key-value pairs.
  # @param model2 [Hash] Hash of key-value pairs.
  # @return [Enumerable<Hash>] See above.
  #
  def self.diff(model1, model2)
    if model1 && model2
      model = model1.merge(model2)
    elsif model1
      model = model1
    elsif model2
      model = model2
    else
      raise ArgumentError, "Both arguments are nil"
    end
    data = []
    model.each do |key, value|
      attr = { name: key }
      if model1 && !model2
        attr[:before_value] = value
        attr[:op]           = :removed
        data << attr
      elsif !model1 && model2
        attr[:after_value] = value
        attr[:op]          = :added
        data << attr
      elsif model1[key].present? && model2[key].blank?
        attr[:before_value] = model1[key]
        attr[:op]           = :removed
        data << attr
      elsif model1[key].blank? && model2[key].present?
        attr[:after_value] = model2[key]
        attr[:op]          = :added
        data << attr
      elsif model1[key].present? && model2[key].present? && model1[key] != model2[key]
        attr[:before_value] = model1[key]
        attr[:after_value]  = model2[key]
        attr[:op]           = :changed
        data << attr
      end
    end
    data
  end

end