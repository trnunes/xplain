module XmapAux
  class Avg < AuxiliaryFunction
    include Xplain::RelationFactory
    
    def initialize(*args, &block)
      super(&block)
      if !@relation
        @relation = args.first
      end
    end
    
    #TODO Treat the case of relation not specified: it should use the input set as the relation
    #TODO generalize the visitor operations
    def prepare(nodes)
      if @relation
        pivot_relation = @relation
        @pivoted_nodes = Xplain::ResultSet.new(nodes: nodes)
          .pivot(group_by_domain: true){relation pivot_relation}.execute
      end
    end
      
    def visit(node)
      
      if @relation
        image = @pivoted_nodes.restricted_image([node])
      else
        image = node.children
      end
      if !image.empty?
        avg_literal = Xplain::Literal.new(image.map{|img| img.item.value}.inject(0, :+)/image.size.to_f)
        [Xplain::Node.new(item: avg_literal)]
      else
        []
      end
      
    end
  end
end