module RefineAux
  class CompositeFilter < GenericFilter
    attr_accessor :filters
    
    def filter(node, child_filters = @filters)
      
    end
      
    def initialize(&block)
      @filters = super &block
    end
    
  end
end
