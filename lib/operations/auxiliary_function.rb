class AuxiliaryFunction
  attr_accessor :args, :server
  def initialize(*args, &block)
    @server = nil
    @args = args
    if block_given?
      self.instance_eval &block
    end
  end
end