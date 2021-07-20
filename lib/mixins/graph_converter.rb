module Xplain
  module GraphConverter
    
    def hash_to_graph(items_hash)
      nodes = []      
      items_hash.each do |item, relations|
        children_set = 
          if relations.is_a? Hash
            hash_to_graph(relations)
          else
            relations.map do |related_item|          
              related_node = Xplain::Node.new(item: related_item)
              related_node
            end
          end
        node = Xplain::Node.new(item: item)
        node.children = children_set
        nodes << node
      end
      if !nodes.first.is_a?(Xplain::Literal)
        return Set.new(nodes)
      else
        nodes
      end   
    end
    
    def to_nodes(items_list)
      items_list.map{|item| Xplain::Node.new(item: item)}
    end
  end
end