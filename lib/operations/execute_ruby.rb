class Xplain::ExecuteRuby < Xplain::Operation
  
  def initialize(args = {})
    super(args)
    @code = args[:code]
  end
  
  def get_results
    result = eval(@code)
    if result.is_a? Xplain::ResultSet
      return result.nodes
    end
    result
  end
end