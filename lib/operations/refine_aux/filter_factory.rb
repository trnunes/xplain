#TODO REFACTOR
module Xplain
  module FilterFactory
    attr_accessor :values
    include EntityFactory
    include RelationFactory
      
    def entity(entity_id)
      @values = [new_entity(entity_id)]
    end

    def type(type_id)
      @values = [new_type(type_id)]
    end
  
    def literal(l_value)    
      @values = [new_literal(l_value)]
    end
  
    def entities(*entities)
      @values = entities.map!{|id| new_entity(id)}
    end
  
    def literals(*literals)    
      @values = literals.map!{|l| new_literal(l)}
    end
  
  end
end