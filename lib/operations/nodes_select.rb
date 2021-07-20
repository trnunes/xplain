class Xplain::NodesSelect < Xplain::Operation
  def initialize(args={}, &block)    
    super(args, &block)
    @ids_list = args[:ids]
    @children_select = args[:children_select]
  end
  
  
  def get_results()
    result_nodes = []
    if !@inputs || @inputs.empty?
      return []
    end
    
    @inputs.each do |input_set|
      @ids_list.each do |id|
        result_nodes += self.by_item_id(input_set, id)
        result_nodes += self.by_node_id(input_set, id)
      end
    end
    result_nodes.map do |n|
      n_copy = n.copy
      n_copy.parent_edges = []
      if !@children_select
        n_copy.children_edges = []
      end
      n_copy 
    end
  end
  
  def by_node_id(result_set, node_id)
    result_set.breadth_first_search(false){|node| node.id == node_id}
  end
  
  def by_item_id(result_set, item_id)
    result_set.breadth_first_search do |node| 
        comparison_value =
          if node.item.is_a? Xplain::Literal
            node.item.value
          else
            node.item.id
          end
        comparison_value == item_id
    end
  end
end