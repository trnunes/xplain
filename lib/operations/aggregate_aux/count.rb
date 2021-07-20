module AggregateAux
  class Count < AuxiliaryFunction
    include Xplain::RelationFactory
    attr_accessor :default_value
    
    def initialize(*args, &block)
      super
      if !@relation
        @relation = args.first
      end
      @default_value = 0
    end
    
    def prepare(nodes)
      if @relation
        pivot_relation = @relation
        @relation.server = @server
        @pivoted_nodes = Xplain::ResultSet.new(nodes: nodes)
          .pivot(group_by_domain: true){relation pivot_relation}.execute
        
      end
    end
      
    def map(node, acc_value)
      
      if @relation
        return count_related_items(node, acc_value)
      end
      acc_value ||= 0      
      acc_value + 1
    end
    
    def count_related_items(node, acc_value)
      acc_value ||= []
      count = @pivoted_nodes.restricted_image([node]).size
      count_node = Xplain::Node.new(item: Xplain::Literal.new(count))
      node.children_edges = []
      node.children = [count_node]
      acc_value << node
      acc_value
    end
  end
end