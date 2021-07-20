module Xplain 
  
  module Relation
    attr_accessor :root, :text, :inverse, :id   
    
    #TODO generalize it!
    def text
      if @text.to_s.empty?
        return Xplain::Namespace.colapse_uri(id)
      end
      @text
    end  
    
    def meta?
      false
    end  

    def domain(offset=0, limit=nil)
      []
    end
    
    def image(offset=0, limit=nil)
      []
    end
       
    def restricted_domain(restriction, options={})
      []
    end
    
    def restricted_image(restriction, options={})
      []
    end
    
    def each_domain(offset=0, limit=-1, &block)
      domains = domain(offset, limit)
      domains.each &block
      domains
    end
  
    def each_image(offset=0, limit=-1, &block)
      image(offset, limit).each &block    
    end
    
    
    def deep_copy
    end
    
    def inverse?
      inverse
    end
    
    def to_s
      @id.to_s
    end
    
    def inspect
      to_s
    end
    
    def eql?(relation)
      relation.is_a?(self.class) && relation.id == self.id && relation.inverse? == self.inverse?
    end
  
    def hash
      id.hash * inverse.hash
    end
  
    alias == eql?
    
  end
end