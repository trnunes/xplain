class Xplain::Xmap < Xplain::Operation
  
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

    input_set = inputs.first
    if input_set.nil? || input_set.children.empty?
      return []
    end
   
    @level ||= input_set.count_levels
    self.map
  end
  
  def map
    input_set = inputs.first
    nodes_to_map = input_set.get_level(@level)
    if @auxiliar_function.respond_to? :prepare
      @auxiliar_function.prepare(nodes_to_map)
    end
    nodes_to_map.each do |node|
      results = node.accept(@auxiliar_function)
      node.children = results
    end
    
    input_set.children
  end
end