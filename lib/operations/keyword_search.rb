class Xplain::KeywordSearch
  ##return a set of nodes
  def get_results(params)
    restriction_nodes = []
    result_nodes = []
    server = params[:server]
    keyword = params[:keyword]
    if keyword.to_s.empty?
      raise MissingArgumentException.new('keyword', 'Keyword Search')
    end
    results = server.match_all(keyword.split(" "), [], 0, 0, params[:exact].to_s == "true")
    result_nodes = results.map{|item| Xplain::Node.new(item: item)}
    result_nodes
    
  end
  
  
end