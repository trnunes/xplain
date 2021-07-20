class Xplain::Group < Xplain::Operation
    
  def initialize(args={}, &block)
    super(args, &block)
    if args[:grouping_relation]
      @auxiliar_function = args[:grouping_relation]
      @level = args[:level]
      args.delete(:grouping_relation)
    end
  end
  
  def get_results()
    if @inputs.nil? || @inputs.empty? || @inputs.first.empty?
      return []
    end
    input_set = inputs_working_copy.first
    
    if input_set.nil? || input_set.children.empty?
      return []
    end
    
    @level ||= input_set.count_levels - 1

    next_to_last_level = input_set.get_level(@level)
    nodes_to_group = []
    next_to_last_level.each do |node|
      nodes_to_group += node.children
    end
    new_groups = []
    @auxiliar_function.prepare(nodes_to_group, new_groups)
    new_groups = @auxiliar_function.group(nodes_to_group)
    
    next_to_last_level.each do |node|
      children = node.children
      node.children_edges = []
      

      new_groups.each do |grouping_node|
        
        children_intersection = grouping_node.children.select{|cnode| children.map{|n|n.item}.include?(cnode.item)}
        if !children_intersection.empty?
          
          children_intersection.each{|child| child.parent_edges = []}
          
          new_grouping_node = Xplain::Node.new(item: grouping_node.item)
          
          new_grouping_node.children = children_intersection
          node << new_grouping_node  
        end
      end
    end
    
    
    groups = input_set.get_level(2)

    # groups.each{|group| group.parent_edges = []}
    
    groups.sort{|g1, g2| g1.to_s <=> g2.to_s}
  end
  
end