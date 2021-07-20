class DisconnectedOperationException < StandardError
  def initialize(msg="The input operation has not been added!")
    super
  end
end