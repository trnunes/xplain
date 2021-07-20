module RankAux
  class ByLevel < AuxiliaryFunction
    include Xplain::RelationFactory
    
    def initialize(*args, &block)
      super(*args, &block)
      @ranking_items_level = args.first
    end
    
    def prepare(nodes)
    end
    
    def compare(node1, node2)
      
       if !@ranking_items_level
         node1_levels_count = node1.count_levels
         node2_levels_count = node2.count_levels
         @ranking_items_level = (node1_levels_count < node2_levels_count) ? node1_levels_count : node2_levels_count 
       end
       
       comparable1 = node1.get_level(@ranking_items_level).first
       comparable2 = node2.get_level(@ranking_items_level).first
       
      
      return comparable1 <=> comparable2 if (comparable1 && comparable2)      
      return -1 if (!comparable1 && comparable2)
      return 1 if (!comparable2 && comparable1)
      return 0
    end
    
  end
end