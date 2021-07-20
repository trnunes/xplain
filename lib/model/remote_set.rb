module Xplain
  class RemoteSet < ResultSet
    attr_accessor :fetched
    
    def initialize(params = {})
      super(params)
      @fetched = false
    end
    
    def fetch
      if !fetched?
        puts
        puts "FETCHING in REMOTE SET: " + self.id + " : " + @intention.to_ruby_dsl
        puts
        rs_nodes = @intention.get_results()
        
        rs_nodes.each{|n| n.parent_edges = []}
        self.children = rs_nodes
        @fetched = true
      end
      
    end
    
    def children
      fetch
      super 
    end
    
    def copy
      mycopy = super
      mycopy.fetched = @fetched
      mycopy
    end
    

    def fetched?
      @fetched
    end
    
    
    def inspect
      if fetched?
        super
      else
        "Class: Xplain::RemoteSet. Nodes: not fetched! fetched? false"
      end
    end    
  end
end