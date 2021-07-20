class Xplain::KeywordSearch < Xplain::Operation
  def initialize(args = {}, &block)
    super(args, &block)
    @keyword_phrase = args[:keyword_phrase]
    
  end
  
  ##return a set of nodes
  def get_results()
    restriction_nodes = []
    result_nodes = []
    if !(@inputs.nil? || @inputs.empty? || @inputs.first.empty?)
      input_set = @inputs.first
      restriction_nodes= input_set.nodes
      result_nodes = input_set.breadth_first_search(true){|node| node.item.text.downcase.include?(@keyword_phrase.to_s.downcase)} 
    end
    
    if !@inplace
      results = @server.match_all(parse_keyword_phrase(), restriction_nodes)      
      result_nodes = results.map{|item| Xplain::Node.new(item: item)}
    end
    
    result_nodes
    
  end
  
  def validate()
    if @keyword_phrase.to_s.empty?
      raise MissingArgumentException.new('keyword phrase', 'Keyword Search')
    end      
  end
  
  #TODO implement the parsing of disjunctive keywords, separated by "|"
  def parse_keyword_phrase()
    @keyword_phrase.to_s.split(" ")
  end
  
end