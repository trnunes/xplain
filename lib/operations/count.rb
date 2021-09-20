class Xplain::Count
  

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
        count_image(nodes_to_map, relation)
        
    else
        count_nodes(nodes_to_map)
    end
    root_input_node.children
  end

  def count_image(nodes, relation)
    image = relation.restricted_image(nodes, group_by_domain: true)
    nodes_hash = nodes.map{|n| [n.item, n]}.to_h
    results = image.map do |node| 
      
      nodes_hash[node.item].children = [Xplain::Node.new(item: Xplain::Literal.new(value: node.children.size))]
      
    end
    # binding.pry

  end

  def count_nodes(nodes)
    parents = nodes.map{|n| n.parent}.uniq.compact
    # binding.pry
    parents.each do |node|
      children = node.children
      node.children = [
        Xplain::Node.new(
          item: Xplain::Literal.new(value: children.size, datatype: :int)
        )
      ]
    end
    
    
    
    
  end
  
  
end