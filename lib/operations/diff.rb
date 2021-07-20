class Xplain::Diff < Xplain::SetOperation
  
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