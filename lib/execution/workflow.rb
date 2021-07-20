class Workflow
  include OperationFactory
  include Xplain::WorkflowWritable
  include Xplain::WorkflowReadable
  
  attr_accessor :id, :nodes, :server, :execution_cache, :history, :annotations

  def initialize(id=nil)
    @nodes = []
    @history = []
    @execution_cache = {}
    @id = id || SecureRandom.uuid
  end
  
  def chain(input_operation, target_operation)
    input_node = nil
    target_node = nil
    
    if @nodes.empty?
      input_node = Xplain::Node.new(input_operation)
      target_node = Xplain::Node.new(target_operation)
      @nodes += [input_node, target_node]
    else
      nodes.each do |node| 
        input_node = node if node.item == input_operation
        target_node = node if node.item == target_operation
      end
    end

    if(input_node.nil?)
      input_node = Xplain::Node.new(input_operation)
      @nodes << input_node
    end
    
    if(target_node.nil?)
      target_node = Xplain::Node.new(target_operation)
      @nodes << target_node
    end
    
    input_node << target_node
    target_node.add_parent input_node
  end
  
  def execute()
    @history = []
    roots = nodes.select{|node| node.parents.empty?}
    roots.map{|root_node| execute_node(root_node)}
  end
  
  def execute_node(node)
    inputs = node.children.map{|child| execute_node(child)}
    if !inputs.empty?
      node.item.input = inputs
    end
    result_set = 
      if Xplain::cache_enabled?
        @execution_cache[node.item.id] ||= node.item.execute 
        @execution_cache[node.item.id]
      else
        node.item.execute
      end
    @history << node.item
    result_set
  end
  
  def last_executed
    @history.last
  end
  
  def handle_operation_instance(operation_new_instance)
    @nodes << Xplain::Node.new(operation_new_instance)
  end
  
  def chain_set_operation(operation_node, depedencies)
    depedencies.each{|dependent_node| chain(operation_node, dependent_node)}
  end
  
  #TODO remove this three methods
  def intersect(nodes)
    chain_set_operation(Intersect.new, nodes)
  end
  
  def union(ndoes)
    chain_set_operation(Unite.new, nodes)
  end
  
  def diff(nodes)
    chain_set_operation(Diff.new, nodes)
  end
  
end