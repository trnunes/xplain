module RankAux
  class ByImage
    
    attr_accessor :relation

    def initialize(params)
      # binding.pry
      if params[:relation].nil?
        raise MissingRelationException.new()
      end
      @relation = params[:relation]
    end
    
    def prepare(nodes)
      #TODO refactor to_item_h and group_by methods in relations
      # binding.pry
      @images_hash = @relation.restricted_image(nodes, group_by_domain: true).nodes.map{|n| [n.item, n.children.map{|c| c.item}]}.to_h
    end
    
    def compare(node1, node2)
       comparable1 = nil
       comparable2 = nil
      if @images_hash[node1.item]
        comparable1 = @images_hash[node1.item].first
      end
      
      if @images_hash[node2.item]
        comparable2 = @images_hash[node2.item].first        
      end
      # binding.pry
      return comparable1 <=> comparable2 if (comparable1 && comparable2)      
      return -1 if (!comparable1 && comparable2)
      return 1 if (!comparable2 && comparable1)
      return 0
    end
    
  end
end