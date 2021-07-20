class Xplain::Aggregate < Xplain::Operation
  
  def initialize(args={}, &block)
    super(args, &block)
    if args[:mapping_relation]
      @auxiliar_function = args[:mapping_relation]
    end
    @level = args[:level]
  end
  
  def get_results()
    if @inputs.nil? || @inputs.empty? || @inputs.first.empty?
      return []
    end

    input_set = inputs_working_copy.first
    if input_set.nil? || input_set.children.empty?
      return []
    end
   
    @level ||= input_set.count_levels
    nodes_to_map = input_set.get_level(@level)
    nodes_parents = nodes_to_map.map{|n| n.parent}.uniq.compact
    
    if @auxiliar_function.respond_to? :prepare
      @auxiliar_function.prepare(nodes_to_map)
    end
    nodes_parents.each do |node|
      current_value = nil
      
      node.children.each{|child| current_value = @auxiliar_function.map(child, current_value)}
      if @auxiliar_function.respond_to? :post_map
        current_value = @auxiliar_function.post_map(current_value)
      end
      if !current_value.respond_to? :each
        current_value = [current_value]
      end
      mapped_nodes = current_value.compact.map do |value_spec|
        parsed_item = parse_item_specs(value_spec)
        if parsed_item.is_a? Xplain::Node
          parsed_item
        else
          Xplain::Node.new(item: parsed_item)
        end
      end.compact
      
      node.children_edges = []
      
      node.children = mapped_nodes
    end
    if @auxiliar_function.respond_to? :default_value
      if @level > 1
        candidates_to_append_default_value = input_set.get_level(@level - 1)
        candidates_to_append_default_value.each do |n|
          if n.children.empty? 
            n.children = [Xplain::Node.new(item: parse_item_specs(@auxiliar_function.default_value))]
          end
        end
      end
    end
    input_set.children
  end
  
  
end