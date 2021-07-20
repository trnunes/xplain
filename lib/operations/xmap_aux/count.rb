module XmapAux
  class Count < AuxiliaryFunction
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
        @pivoted_nodes = Xplain::ResultSet.new(nodes: nodes)
          .pivot(group_by_domain: true){relation pivot_relation}.execute
      end
    end
      
    def visit(node)
      if @relation
        image_size = @pivoted_nodes.restricted_image([node]).size
        literal = Xplain::Literal.new(image_size)
      else
        literal = Xplain::Literal.new(node.children.size)
      end
      
      return [Xplain::Node.new(item: literal)]
    end
  end
end