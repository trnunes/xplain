module RankAux
  class ByText
    
    attr_accessor :relation

    def initialize(params={})
    end
    
    def prepare(nodes)
    end
    
    def compare(node1, node2)
        node1 <=> node2
    end
    
  end
end