class ApprovalState
  PENDING  = 'pending'
  APPROVED = 'approved'
  REJECTED = 'rejected'

  ##
  # @return [Enumerable<String>]
  #
  def self.all
    self.constants.map{ |k| const_get(k) }
  end
end
