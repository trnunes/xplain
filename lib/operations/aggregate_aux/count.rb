module AggregateAux
  class Count
    
    attr_accessor :default_value
    
    def initialize(params = {})
      @relation = params[:relation]
      @default_value = Xplain::Literal.new(value: 0)
      @acc_value = Xplain::Literal.new(value: 0)
    end
    
    def prepare(nodes)
      if @relation
        pivot_results = Xplain::Pivot.new.get_results(relation: @relation, group_by_domain: true)
        @pivoted_nodes = Xplain::ResultSet.new(nodes: pivot_results)
      end
    end
      
    def map(node, acc_value)
      
      if @relation
        return count_related_items(node)
      end
      
      acc_value + 1
    end
    
    def count_related_items(node, acc_value)
      acc_value ||= []
      count = @pivoted_nodes.restricted_image([node]).size
      count_node = Xplain::Node.new(item: Xplain::Literal.new(value: count))
      node.children_edges = []
      node.children = [count_node]
      acc_value << node
      acc_value
    end
  end
end