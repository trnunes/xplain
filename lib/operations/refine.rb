class Xplain::Refine < Xplain::Operation
  include Xplain::FilterFactory
  
  def initalize(args = {}, &block)
    super(args, &block)
    if !@auxiliar_function && args[:filter]
      @auxiliar_function = args[:filter]
    end
  end
  
  def pivot_to_level_2(nodes)
    Set.new(nodes.map do |node|
      ancestors = node.ancestors
      ancestors[ancestors.size - 2]
    end)
  end
  
  def filter_children(parent_nodes, nodes_to_keep)
    result_nodes = parent_nodes.class.new
    node_items_to_keep = Set.new(nodes_to_keep.map{|node| node.item}.to_a)
    parent_nodes.each do |parent_node|
      parent_node.children = parent_node.children.select{|child| node_items_to_keep.include? child.item} 
      result_nodes << parent_node if parent_node.children.size > 0
    end
    result_nodes
  end
  
  def get_results()
    
    #TODO duplicated code. Generalize this validation!
    if @inputs.nil? || @inputs.empty? || @inputs.first.empty?
      return []
    end

    input_set = inputs_working_copy.first
    if(input_set.children.empty?)
      return []
    end
    @level ||= input_set.count_levels
    
    input_nodes = input_set.get_level(@level)
    in_memory_result_nodes = input_nodes
    final_result_nodes = []
    #TODO implement composite filter execution correctly. It does not respect the composite tree
    non_interpretable_filters = @server.validate_filters(@auxiliar_function)
    if !non_interpretable_filters.empty?
      interpreter = InMemoryFilterInterpreter.new(non_interpretable_filters, input_nodes)

      in_memory_result_nodes = @auxiliar_function.accept(interpreter)
    end

    result_nodes_hash = {}
    in_memory_result_nodes.each do |node|
      result_nodes_hash[node.item] = [] if !result_nodes_hash.has_key?(node.item)
      result_nodes_hash[node.item] << node
    end

    
    final_result_nodes = in_memory_result_nodes
    if @server.can_filter? @auxiliar_function
      final_result_nodes = []

      @server.filter(in_memory_result_nodes.map{|node| node.item}, @auxiliar_function).each do |item_to_keep|

        final_result_nodes += result_nodes_hash[item_to_keep].to_a

      end      
    end    
    
    if @level > 2

      remove_filtered_siblings(final_result_nodes)

      final_result_nodes = pivot_to_level_2(final_result_nodes)
    end

    final_result_nodes.each{|node| node.parent_edges = []}
    final_result_nodes
  end

  def remove_filtered_siblings(nodes)

    if !nodes.empty?
      level_up_nodes = []
      parents = nodes.map{|node| node.parent}.compact
      parents.each do |current_parent|
        current_parent.children = current_parent.children & nodes

        if !current_parent.children.empty?
          level_up_nodes << current_parent
        else
          current_parent.parent.remove_child(current_parent) if current_parent.parent
        end
        
      end
      remove_filtered_siblings(level_up_nodes)
    end
  end
end