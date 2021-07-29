#TODO IMPLEMENT SERVER DELEGATORS FOR OPERATIONS COVERED BY THE REPOSITORY. IF THE OPERATION IS AVAILABLE, IT MUST BE DELEGATED TO  THE REPOSITORY.

class Xplain::Operation
  
  include Xplain::GraphConverter
  include Xplain::DslCallable
  
  attr_accessor :params, :server, :inputs, :id, :auxiliar_function, :definition_block, :args, :session

  @base_dir = ""
  class << self
    attr_accessor :base_dir
  end
  
  def initialize(args={}, &block)
    if !args.is_a? Hash
      args = {inputs: args}
    end
    @session = args[:session]
    @args = args
    @id = args[:id] || SecureRandom.uuid
    setup_input args
    @server = args[:server]
    @level = args[:level]
    @limit = args[:limit] || 0
    @debug = args[:debug] || false
    @relation = args[:relation]
    @visual = args[:visual] || false
    @inplace = args[:inplace] || false
    if block_given?
      @definition_block = block 
      self.instance_eval &@definition_block
    end
  end

  def inplace?
    @inplace
  end

  def self.operation_class?(klass)
    operation_subclasses = ObjectSpace.each_object(Class).select {|space_klass| space_klass < Xplain::Operation }
    operation_subclasses.include? klass
  end
  
  def setup_input(args)
    inputs = args[:inputs]
    is_result_set_or_operation = inputs.is_a?(Xplain::ResultSet) || inputs.is_a?(Xplain::Operation)
    is_array_of_nodes =  inputs.is_a?(Array) && (inputs.map{|input| input.class}.uniq == [Xplain::Node])
    if is_result_set_or_operation || is_array_of_nodes 
      @inputs = [inputs]
    else 
      @inputs = inputs
    end
    @inputs ||= []
  end
  
  def server=(server)
    @server = server
    if @auxiliar_function && @auxiliar_function.respond_to?(:server)
      @auxiliar_function.server = @server
    end
  end
  
  #TODO implement this operation to express the operation and its parameters  
  def to_expression
    self.class.to_s.downcase
  end
  
  def summarize
    self.class.to_s.downcase.gsub("xplain::", "")
  end
  
  
  def input=(operation_input)
    setup_input operation_input
  end
  
  def to_ruby_dsl
    intention_parser = DSLParser.new
    
    inputs_codes = @inputs.map do |i|
      if i.is_a? Xplain::ResultSet
        if i.intention.is_a? Xplain::Operation
          i.intention.to_ruby_dsl
        else
          i.intention.to_s
        end
      elsif i.is_a? Xplain::Operation
        i.to_ruby_dsl
      else
        i.intention.to_s
      end
    end
    
    ruby_code = intention_parser.to_ruby(self, false)
    constructor_regexp = @inputs.map{|i| "(.*)"}.join(",")
    constructor_replacements = ruby_code.scan(/\.new\(\[#{constructor_regexp}\]\)/)
    if !constructor_replacements.empty?
      for i in (0..inputs_codes.size-1) 
        ruby_code.gsub!(constructor_replacements[0].to_a[i].to_s, inputs_codes[i])
      end
    elsif !inputs_codes.compact.empty?
      ruby_code = inputs_codes.first.to_s + "."+ ruby_code 
    end
    
    ruby_code.gsub(/(Xplain::Load\.new\(https?:\/\/[\S]+\))\./, "")
  end
  
  def to_ruby_dsl_sum
    to_ruby_dsl.gsub(" ", "").gsub("\n", "").gsub(";", "")
    
  end

  def reify
    input_resultsets = inputs.map do |input|
      input_intention = nil
      
      if input.is_a? Xplain::Operation
        input_intention = input
      else
        input_intention = input.intention
      end
      
      
      if !input_intention
        if input.id.to_s.empty?
          input.save()
        end
        input
      else
        input_intention.execute().save()
      end
    end
    binding.pry
    inputs = input_resultsets
  end
  
  def execute
     
    if @auxiliar_function && @auxiliar_function.respond_to?(:server)
      @auxiliar_function.server = @server
    end
    validate()
    # reify()
    resultset = Xplain::ResultSet.new(intention: self)
    # binding.pry
    result_nodes = get_results()
    
    result_nodes.each{|node| node.parent_edges = []}
    resultset.children = result_nodes
    resultset.fetched = true
    
    resultset
  end
  
    
  def parse_item_specs(item_spec)
    return if item_spec.nil?
    if item_spec.is_a?(Xplain::Item) || item_spec.is_a?(Xplain::Node)
      return item_spec
    elsif item_spec.is_a? Hash
      item_class = item_spec.keys.first
      item_id = item_spec[item_class]
      item = eval(item_class.to_s.camelcase + ".new(#{item_id})")
      if item.class == xplain::Literal && item_spec.has_key?(:datatype)
        item.datatype = item_spec[:datatype]
      end
      return item
    else
      return Xplain::Literal.new(item_spec)
    end
    
  end
  
  def visual?
    @visual
  end
  
  def inputs_working_copy
    inputs.map{|i|i.copy}
  end
  
  def validate
    true
  end
  
  def get_results
    []
  end

  def handle_auxiliary_function(klass, *args, &block)

    @auxiliar_function = super
  end
  
  def eql?(operation)
    operation.is_a?(self.class) && @id == operation.id
  end

  def hash
    @id.hash
  end

  alias == eql?
  
end
