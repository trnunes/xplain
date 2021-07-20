module Xplain
  #TODO implement the group_by_domain option for mixed paths
  class PathRelation < Item
    include Xplain::Relation
    include Xplain::GraphConverter
    include Xplain::PathRelationWritable
    include Xplain::PathRelationReadable

    
    extend Forwardable
    attr_accessor :inverse, :relations, :limit
    def_delegators :@relations, :map, :each, :size, :unshift, :last
  
  
    def initialize(args = {})
      super(args)      
      @limit = args[:limit]
      @relations = args[:relations]
      @domain_restriction = args[:domain_restriction] || []
      @image_restriction = args[:image_restriction] || []

    end
  
    def reverse
      args = {}
      args[:relations] = relations.map{|r| r.reverse}
      args[:limit] = @limit
      args[:server] = @server
      args[:domain_restriction] = @domain_restriction
      args[:image_restriction] = @image_restriction
      
      Xplain::PathRelation.new(args)
    end
    
    def id
      @relations.map{|r| r.id}.join("/")
    end
  
    def can_fire_path_query
      are_all_schema_relations = (@relations.select{|r| !r.is_a? Xplain::SchemaRelation}.size == 0)
      are_all_schema_relations
    end
  
    def inverse?
      (@relations.select{|r| r.inverse?}.size == @relations.size)
    end
  
  
    def image(offset=0, limit=-1)
      ResultSet.new nodes: build_image_results(@server.image(self, [], offset, limit))
    end
  
    def domain(offset=0, limit=-1)
      ResultSet.new nodes: build_domain_results(@server.domain(self, [], offset, limit))    
    end
  
    def restricted?
      !(@image_restriction.empty? && @domain_restriction.empty?)
    end
  
    def each_domain(offset=0, limit=-1, &block)

      domains = domain(offset, limit)
      domains.each &block
      domains
    end
  
  
    def server=(server)
      @server = server
      @relations.each{|r| r.server = server}
    end
  
    
    def mixed_path_restricted_image(items, options = {})
      relations = @relations

      result_items = items

      relations.each do |r|
      
        partial_images = r.restricted_image(Set.new(result_items), options)

        partial_images_hash = {}

        partial_images.each do |item| 
          if(!partial_images_hash.has_key? item.parent)
            partial_images_hash[item.parent] = []
          end
          partial_images_hash[item.parent] << item
        
        end
      
        new_result_items = []
        result_items.each do |item|
        
          if(partial_images_hash.has_key? item)
            partial_images_hash[item].each do |next_image|
            
              next_image.parent = item
              new_result_items << next_image
            end
          end
        end

        result_items = new_result_items

      end
      build_results result_items
    end
  
    def mixed_path_restricted_domain(items, options = {})
      relations = @relations.reverse
      result_pairs = []
      result_pairs = items
      relations.each do |r|
        result_pairs = r.restricted_domain(Set.new(result_pairs), options)
      end
      ResultSet.new nodes: build_results(result_pairs)
    end
    
    def schema_restricted_image(restriction, options = {})
      @server.restricted_image(self, restriction, options)
    end
    
    def schema_restricted_domain(restriction, options = {})
      @server.restricted_domain(self, restriction, options)
    end
  
    def restricted_image(restriction, options = {})

      if can_fire_path_query
          schema_restricted_image(restriction, options)
      else
          mixed_path_restricted_image(restriction, options)
      end
    end
  
    def restricted_domain(restriction, options = {})
      if can_fire_path_query
          schema_restricted_domain(restriction, options)
      else
          mixed_path_restricted_domain(restriction, options)
      end
    end
  
    def get_level(level, parents_restriction = [], children_restriction = [], offset = 0, limit = -1)
      if(level == 2)
        if(!children_restriction.empty?)
          fetch_restricted_domain(children_restriction, {offset: offset, limit: limit})
        else
          domain(offset, limit)
        end
      elsif (level == 3)
        if(!parents_restriction.empty?)
          fetch_restricted_image(parents_restriction, {offset: offset, limit: limit})
        else
          image(offset, limit)
        end      
      
      end
    end
  
  
        
    def text
      if @text.to_s.empty?
        @text = @relations.map{|r| r.text}.join("/")
      end
      @text
    end
  
    def eql?(relation)
      (self.id == relation.id) && (relation.inverse == self.inverse)
    end
  
    def hash
      @id.hash * inverse.hash
    end
  
    def leaves
      image()
    end
  
    alias == eql?

    def to_s
      id + ": " + text
    end

    def intention
      "Xplain::PathRelation.new(text: \"#{text}\", relations: [#{@relations.map{|relation| parse_schema_relation relation}.join(", ")}])"
    end

    def parse_schema_relation(schema_relation)
      "Xplain::SchemaRelation.new(id: '#{schema_relation.id}', inverse: #{schema_relation.inverse})"
    end

  end
end