
class Xplain::Rank
  
  
  def get_results(params)

    input_nodes = params[:input_nodes]
    if input_nodes.to_a.empty?
      return []
    end
    
    copied_nodes = input_nodes.map{|n| n.copy}
    
    
    order = params[:order]
    
    multiplier = (order == :desc) ? -1:1
    
    aux_function = params[:function] || RankAux::ByText.new
    aux_function.prepare(copied_nodes)
    rank(copied_nodes, aux_function, multiplier)
  end

  def rank(nodes, aux_function, mult)
    ranked_nodes = nodes.sort{|n1, n2| mult * aux_function.compare(n1, n2)}
    ranked_nodes.each do |n|
      n.children = rank(n.children, aux_function, mult)
    end
    ranked_nodes
  end
end