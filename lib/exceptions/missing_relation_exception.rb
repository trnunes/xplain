class MissingRelationException < StandardError
  def initialize(msg = "You should provide a relation here!")
    super
  end
end