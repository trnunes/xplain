module GroupAux
  class ByImage
    
    def initialize(params={})
      if params[:relation].nil?
        raise MissingRelationException
      end
      @relation = params[:relation]
    end

    def prepare(items, groups)
    end
    
    def group(nodes)
      if nodes.empty?
        return []
      end

      result_hash = {}
      result_set = @relation.restricted_image(nodes, group_by_domain: true)
      # binding.pry
      result_set.last_level.each do |leaf|
        
        if !result_hash.has_key? leaf.item
          result_hash[leaf.item] = Xplain::Node.new(item: leaf.item)
        end
        # binding.pry
        result_hash[leaf.item] << Xplain::Node.new(item: leaf.parent.item)
      end
      result_hash.values
    end
  end
end
