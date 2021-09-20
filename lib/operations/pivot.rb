###
# The Pivot operation, receives a relation, a group_by_domain and a uniq param
###

class Xplain::Pivot

  def get_results(params)

    input_nodes = params[:input_nodes]
    if input_nodes.to_a.empty?
      return []
    end

    copied_nodes = input_nodes.map{|n| n.copy}
    root_input_node = Xplain::Node.new(children: copied_nodes)
    
    group_by_domain = params[:group_by_domain].to_s == "true"

    relation = params[:relation]
    level = params[:level] || root_input_node.count_levels
    limit = params[:limit] || 0

    if !relation
      raise MissingRelationException.new
    end

    #TODO repeated code, generalize it!
    
    level_items = root_input_node.get_level(level)
    level_items = level_items[0..limit] if limit > 0
    # 
    
    result_set = relation.restricted_image(level_items, group_by_domain: group_by_domain, preserve_input: false)
    # binding.pry
    if group_by_domain
      children_by_item = result_set.to_hash_children_node_by_item
      
      level_items.each do |node|
        if children_by_item.has_key? node.item
          
          node.children = children_by_item[node.item].first.children.map{|child| child.parent_edges = []; child}.uniq{|c| c.item}
        end
        
      end
      
      nodes_to_return = root_input_node.get_level(2)
    else
      
      nodes_to_return = result_set.nodes
      if !result_set.contain_literals?
        nodes_to_return = Xplain::Node.uniq_by_item nodes_to_return 
      end
    end
    # binding.pry
    nodes_to_return.sort
    
  end
  

end
