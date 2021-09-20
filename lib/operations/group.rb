class Xplain::Group
    
  def get_results(params)
    input_nodes = params[:input_nodes]
    if input_nodes.to_a.empty?
      return []
    end
    
    copied_nodes = input_nodes.map{|n| n.copy}
    root_input_node = Xplain::Node.new(children: copied_nodes)
    level = params[:level]
    level ||= root_input_node.count_levels - 1
    aux_function = params[:function]

    next_to_last_level = root_input_node.get_level(level)
    nodes_to_group = []
    next_to_last_level.each do |node|
      nodes_to_group += node.children
    end
    new_groups = []
    aux_function.prepare(nodes_to_group, new_groups)
    new_groups = aux_function.group(nodes_to_group)
    
    next_to_last_level.each do |node|
      children = node.children
      node.children_edges = []
      

      new_groups.each do |grouping_node|
        
        children_intersection = grouping_node.children.select{|cnode| children.map{|n|n.item}.include?(cnode.item)}
        if !children_intersection.empty?
          
          children_intersection.each{|child| child.parent_edges = []}
          
          new_grouping_node = Xplain::Node.new(item: grouping_node.item)
          
          new_grouping_node.children = children_intersection
          node << new_grouping_node  
        end
      end
    end
    
    
    groups = root_input_node.get_level(2)

    # groups.each{|group| group.parent_edges = []}
    
    groups.sort{|g1, g2| g1.to_s <=> g2.to_s}
  end
  
end