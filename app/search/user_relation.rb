class UserRelation < AbstractRelation

  LOGGER = CustomLogger.new(UserRelation)

  protected

  def get_class
    User
  end

end