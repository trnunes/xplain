class CFilter < GenericFilter
  #TODO correct fitler constructor and validation. Some filters may not need a relation specification
  #TODO include *args in SimpleFilter and GenericFilter
  attr_accessor :args
  def initialize(*args)    
    filter_spec = args.first
    @args = filter_spec
    if filter_spec.nil?
      raise "Missing filter specification!"
    elsif filter_spec.is_a? Hash
      @filter_name = filter_spec[:name]
      @filter_code = filter_spec[:code]
    else
      @filter_code = filter_spec
    end
    
  
    
    if !@filter_code
      raise MissingParameterException("you should provide a filter code here!")
    end
  end
  def filter(node)
    return eval("lambda{#{@filter_code}}").call node
  end
end