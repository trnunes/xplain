class MissingAuxiliaryFunctionException < StandardError
  def initialize(msg = "You should provide an auxiliary function here!")
    super
  end
end