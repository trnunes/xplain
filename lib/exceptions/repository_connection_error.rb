class RepositoryConnectionError < StandardError
  def initialize(msg = "Cannot connect the session repository")
    super
  end
end 