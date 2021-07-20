module XmapAux
  class Sum < AuxiliaryFunction
    include Xplain::RelationFactory
    
    def initialize(*args, &block)
      super(&block)
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
      image = []
      if @relation
        image = @pivoted_nodes.restricted_image [node]
      else
        image = node.children
      end
      
      if !image.empty?
        sum = image.map do |img|
          img_item = img.item 
          raise NumericItemRequiredException if !img_item.is_a?(Xplain::Literal)
          img.item.value.to_f
        end.inject(0, :+)
        [Xplain::Node.new(item: Xplain::Literal.new(sum))]
      else
        []
      end
    end
  end
end