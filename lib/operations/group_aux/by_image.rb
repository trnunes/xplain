module GroupAux
  class ByImage < GroupingRelation  
    include Xplain::RelationFactory
    
    attr_accessor :groups_hash
    def initialize(*args, &block)
      super
      @groups_hash = {}
      if !block_given?
        @relation = args.first
      end    
    end
  
    def group(nodes)
      if nodes.empty?
        return []
      end
      if @relation.nil?
        raise MissingRelationException
      end

      result_hash = {}
      @relation.server = @server
      result_set = @relation.restricted_image(nodes, group_by_domain: true)
      result_set.last_level.each do |leaf|
        if !result_hash.has_key? leaf.item
          result_hash[leaf.item] = Xplain::Node.new(item: leaf.item)
        end
        result_hash[leaf.item] << Xplain::Node.new(item: leaf.parent.item)
      end
      result_hash.values
    end
  end
end
