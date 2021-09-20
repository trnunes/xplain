class Xplain::Avg
  

  def get_results(params)
    input_nodes = params[:input_nodes]
    if input_nodes.to_a.empty?
      return []
    end

    copied_nodes = input_nodes.map{|n| n.copy}
    root_input_node = Xplain::Node.new(children: copied_nodes)
    level = root_input_node.count_levels
    if params[:level]
      level = params[:level].to_i + 1
    end

    relation = params[:relation]

    nodes_to_map = root_input_node.get_level(level)

    if relation
      avg_image(nodes_to_map, relation)
    else
      avg_nodes(nodes_to_map)
    end
    root_input_node.children
  end

  def avg_image(nodes, relation)
    image = relation.restricted_image(nodes, group_by_domain: true)
    nodes_hash = nodes.map{|n| [n.item, n]}.to_h
    image.each do |node|
      avg = Xplain::Literal.new(value: 0)
      values_array = node.children.map{|c| c.item.value.to_f if c.item.is_a? Xplain::Literal}.compact
      sum = values_array.inject(:+)
      if !node.children.empty?
          avg = Xplain::Literal.new(value: sum/node.children.size)
          
      end

      nodes_hash[node.item].children = [Xplain::Node.new(item: avg)]
        
    end
  end

  def avg_nodes(nodes)
    parents = nodes.map{|n| n.parent}.uniq.compact
    parents.each do |node|
      children_values = node.children.map{|c| c.item.id.to_f}
      divider = children_values.size == 0 ?  1 : children_values.size
      node.children = [
        Xplain::Node.new(
          item: Xplain::Literal.new(value: children_values.inject(:+)/divider, datatype: :float)
        )
      ]
    end
  end
  
  
end