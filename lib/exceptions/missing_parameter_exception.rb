class MissingParameterException < StandardError
  def initialize(msg = "Wrong number of parameters")
    super
  end
end