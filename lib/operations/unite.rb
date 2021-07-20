class Xplain::Unite < Xplain::SetOperation
  
  
  def compute(input, target)    
    node_unite(input, target)
    input.children
  end
  
  def node_unite(n1, n2)
    
    n2_children_node_by_item_hash = n2.to_hash_children_node_by_item    
    children_are_literal_leaves = !n2.children.empty? && n2.children.first.item.is_a?(Xplain::Literal) && n2.children.first.children.empty?
    if children_are_literal_leaves
      n1.append_children n2.children
      return
    end
    
    n1_children_node_by_item_hash = n1.to_hash_children_node_by_item
    children_items_in_common = n1_children_node_by_item_hash.keys & n2_children_node_by_item_hash.keys
    n2_children_to_append = n2_children_node_by_item_hash.keys - children_items_in_common
    
    n2_children_to_append.each do |n2_child_item|
      n2_only_nodes = n2_children_node_by_item_hash[n2_child_item]
      n1.append_children n2_only_nodes
    end

    children_items_in_common.each do |common_child_item|
      n1_nodes = n1_children_node_by_item_hash[common_child_item]
      n2_nodes = n2_children_node_by_item_hash[common_child_item]
      n1_nodes.each do |n1_child_node|
        n2_nodes.each do |n2_child_node|
          node_unite(n1_child_node, n2_child_node)
        end
      end
    end
  end
end