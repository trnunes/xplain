class GenericFilter < AuxiliaryFunction
  include Xplain::DslCallable
   
  def accept(filter_interpreter)
    filter_interpreter.visit(self)
  end
  
  def initialize(&block)
    self.instance_eval &block
  end
  
  def filter(node)
    true
  end
  
  #TODO remove redundance with Operation class. Idea: move the method missing to a module
  
end