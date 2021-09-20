class Xplain::Aggregate
  
  
  def get_results(params)
    input_nodes = params[:input_nodes]
    if input_nodes.to_a.empty?
      return []
    end

    copied_nodes = input_nodes.map{|n| n.copy}
    root_input_node = Xplain::Node.new(children: copied_nodes)

    level = params[:level]
    level ||= root_input_node.count_levels
    aux_function = params[:function]
    if aux_function.nil?
      raise "Map function requires a auxiliar function as parameter!"
    end

    nodes_to_map = root_input_node.get_level(level)
    
    nodes_parents = nodes_to_map.map{|n| n.parent}.uniq.compact
    
    aux_function.prepare(nodes_to_map)
    
    nodes_parents.each do |node|
      current_value = nil
      
      node.children.each{|child| current_value = aux_function.map(child, current_value)}
      
      if aux_function.respond_to? :post_map
        current_value = aux_function.post_map(current_value)
      end
      
      if !current_value.respond_to? :each
        current_value = [current_value]
      end
      
      mapped_nodes = current_value.compact
      
      node.children_edges = []
      
      node.children = mapped_nodes
    end
    if aux_function.respond_to? :default_value
      if level > 1
        candidates_to_append_default_value = root_input_node.get_level(level - 1)
        candidates_to_append_default_value.each do |n|
          if n.children.empty? 
            n.children = [Xplain::Node.new(item: parse_item_specs(aux_function.default_value))]
          end
        end
      end
    end
    root_input_node.children
  end
  
  
end