class InMemoryFilterInterpreter
  
  def initialize(filters_to_execute = [], nodes_to_filter)
    @filters_to_execute = filters_to_execute
    @nodes_to_filter = nodes_to_filter
  end
  
  def visit(filter_expr)
    if !filter_expr.is_a? RefineAux::CompositeFilter
      
      @nodes_to_filter.select{|node| filter_expr.filter(node)}
    else

      @nodes_to_filter.select do |node|
         
        filter_expr.filter(node, filter_expr.filters & @filters_to_execute)
      end
    end
    
  end
end