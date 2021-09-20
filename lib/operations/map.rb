class Xplain::Map
  
  def get_results(params)
    input_nodes = params[:input_nodes]
    if input_nodes.to_a.empty?
      return []
    end

    copied_nodes = input_nodes.map{|n| n.copy}
    root_input_node = Xplain::Node.new(children: copied_nodes)

    level = params[:level]
    level ||= input_set.count_levels
    aux_function = params[:function]
    if aux_function.nil?
      raise "Map function requires a auxiliar function as parameter!"
    end
    self.map(aux_function, level, root)
  end
  
  def map(aux_function, level, root)
    nodes_to_map = root.get_level(level)
    
    aux_function.prepare(nodes_to_map)
    
    nodes_to_map.each do |node|
      results = node.accept(aux_function)
      node.children = results
    end
    
    nodes_to_map
  end
end