class Xplain::Htransform < Xplain::Operation
  
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
    if @auxiliar_function.respond_to? :prepare
      @auxiliar_function.prepare(nodes_to_map)
    end
    nodes_to_map.each do |node|
      mapped_items_specs = node.children.map{|child| @auxiliar_function.map(node)}
      mapped_nodes = mapped_children_specs.map do |item_spec|
        if !item_spec.respond_to? :each
          item_spec = [item_spec]
        end
        items = item_spec.map{|sub_item_spec| parse_item_specs sub_item_spec}.compact
        items.map{|item| Node.new(item: item)}
      end.flatten(1)
      
      node.children_edges = []
      node.children = mapped_nodes
    end
    input_set.children
  end
  
  
end