module AggregateAux
  class Avg
    
    
    def initialize(params = {})
      @relation = params[:relation]
    end    

    def prepare(nodes)
      if @relation
        pivot_results = Xplain::Pivot.new.get_results(relation: @relation, group_by_domain: true)
        @pivoted_nodes = Xplain::ResultSet.new(nodes: pivot_results)
      end
    end    
      
    def map(node, agg_value)
      
      if @relation
        return avg_related_items(node, agg_value)
      end
      
      agg_value ||= [0,0]      
      agg_value[0] += node.item.value.to_f
      agg_value[1] += 1
      agg_value
    end    
    
    def post_map(agg_value)
      if @relation
        return agg_value
      end
      agg_value[0]/agg_value[1]
    end
    
    def avg_related_items(node, agg_value)
      agg_value ||= []
      image = @pivoted_nodes.restricted_image([node])
      avg_literal = image.map{|img| img.item.value}.inject(0, :+)/image.size.to_f
      avg_node = Xplain::Node.new(item: Xplain::Literal.new(value: avg_literal))
      node.children = [avg_node]
      agg_value << node
      agg_value
    end
  end
end