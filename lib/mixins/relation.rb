module Xplain 
  
  module Relation
    attr_accessor :root, :text, :inverse, :id   
    
    def self.create(descriptor)
      
      relation_descs = descriptor.scan(/([^<-]*->)|([^->]*<-)/)
      # binding.pry
      created_relation = nil
      
      if relation_descs.empty?
        return Xplain::SchemaRelation.new(id: descriptor)
      end
      
      relations = relation_descs.map do |r| 
        r.compact!
        relation_desc = r.first
        relation_params = {}

        if relation_desc.include?("<-")
          relation_params[:inverse] = true
        end
        relation_params[:id] = relation_desc.gsub(/(->)|(<-)/, "")
        Xplain::SchemaRelation.new(relation_params)
      end

      if relations.size > 1
        return Xplain::PathRelation.new(relations: relations)
      end
      # binding.pry
      return relations.first
    end
    #TODO generalize it!

    def to_h
      {
        type: self.class.to_s,
        server: @server.id,
        id: descriptor()
      }
    end

    def text
      if @text.to_s.empty?
        return Xplain::Namespace.colapse_uri(id)
      end
      @text
    end  
    
    def size
      1
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