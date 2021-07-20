module AggregateAux
  class Sum < AuxiliaryFunction
    include Xplain::RelationFactory
    
    def initialize(*args, &block)
      super
      if !@relation
        @relation = args.first
      end
    end
    
    def prepare(nodes)
      if @relation
        pivot_relation = @relation
        @relation.server = @server
        @pivoted_nodes = Xplain::ResultSet.new(nodes: nodes)
          .pivot(group_by_domain: true){relation pivot_relation}.execute
      end
    end
    
      
    def map(node, agg_value)
      
      if @relation
        return sum_related_items(node, agg_value)
      end
      
      agg_value ||= 0      
      agg_value += node.item.value.to_f
      agg_value
    end    
    
    def sum_related_items(node, agg_value)
      agg_value ||= []
      agg_value << node
      image = @pivoted_nodes.restricted_image([node])
      if image.empty?
        return agg_value
      end

      sum_literal = image.map do |img|
        raise NumericItemRequiredException if !img.item.is_a?(Xplain::Literal) 
        img.item.value 
      end.inject(0, :+)
      sum_node = Xplain::Node.new(item: Xplain::Literal.new(sum_literal.to_f))
      node.children = [sum_node]
      agg_value
    end
  end
end