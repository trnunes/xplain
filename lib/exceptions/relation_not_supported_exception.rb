class RelationNotSupportedException < StandardError
  def initialize(msg = "This relation is currently not supported by the server!")
    super
  end
end