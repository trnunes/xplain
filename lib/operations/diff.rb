class Xplain::Diff
  def get_results(params)
    input_sets = params[:input].to_a.map do |nodes| 
      Xplain::Node.new(children: nodes)
    end.compact
    
    if input_sets.empty?
      return []
    end

    set1 = input_sets.delete_at(0)
    
    input_sets.each do |set2|
      union_nodes = compute(set1, set2)
      set1 = Xplain::Node.new(children: union_nodes)
    end
    
    set1.children
  end
    
  def compute(input, target)
    parent = Xplain::Node.new()
    node_diff(input, target)
    return input.children
  end
  
  def node_diff(n1, n2)
    n1.children.each do |child_n1|
      n2.children.each do |child_n2|
        if child_n1.item == child_n2.item
          node_diff(child_n1, child_n2)
          if child_n1.leaf? && child_n2.leaf?
            remove_path(child_n1)
          end
        end
      end
    end
  end
  
  def remove_path(leaf_node)
    node = leaf_node
    parent = leaf_node.parent
    while parent
      parent.remove_child(node) if node.leaf?
      node = parent
      parent = node.parent
    end
  end
  
end