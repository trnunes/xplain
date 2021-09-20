class Xplain::Sum
  

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

    if level < 1 || level > root_input_node.count_levels
      raise "Invalid level parameter: #{level}. It should be 1 < level < #{root_input_node.count_levels}"
    end

    relation = params[:relation]

    nodes_to_map = root_input_node.get_level(level)
    # binding.pry
    if relation
        sum_image(nodes_to_map, relation)
    else
        sum_nodes(nodes_to_map)
    end
    # binding.pry
    root_input_node.children
  end

  def sum_image(nodes, relation)
    image = relation.restricted_image(nodes, group_by_domain: true)
    nodes_hash = nodes.map{|n| [n.item, n]}.to_h
    image.each do |node|
        
        values_array = node.children.map{|c| c.item.value.to_f if c.item.is_a? Xplain::Literal}.compact
        sum = values_array.inject(:+)
        nodes_hash[node.item].children = [
          Xplain::Node.new(item: Xplain::Literal.new(value: sum))
        ]
    end
  end

  def sum_nodes(nodes)
    parents = nodes.map{|n| n.parent}.uniq.compact
    parents.each do |node|
      children_values = node.children.map{|c| c.item.id.to_f}
      node.children = [
        Xplain::Node.new(
          item: Xplain::Literal.new(value: children_values.inject(:+), datatype: :float)
        )
      ]
    end
    
  end
  
  
end