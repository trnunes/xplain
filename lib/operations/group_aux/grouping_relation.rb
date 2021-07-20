module GroupAux
  class GroupingRelation < AuxiliaryFunction
  
    def initialize(*args, &block)
      super(&block)
    end
  
    def prepare(items, groups)
    end
  
    def group(item, groups)
      return nil
    end
  end
end