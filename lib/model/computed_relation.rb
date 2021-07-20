module Xplain
  class ComputedRelation
    include Relation
    attr_accessor :domain_nodes
    def initialize(args = {})
      @id = args[:id]
      @domain_nodes = args[:domain] || []
      @inverse = args[:inverse]
      @inverse ||= false
    end
      
    def fetch_graph(items, limit=nil, offset=nil)
      restricted_image(items, {limit: limit, offset: offset}).map{|item| item.parent}.uniq
    end
  
    def schema?
      false
    end
    
    def reverse
      Xplain::SchemaRelation.new(id: id, inverse: !inverse?)
    end
    
    def image(offset=0, limit=nil)
      ResultSet.new(nil, Set.new(@domain_nodes.map{|dnode| dnode.children}.flatten))
    end
  
    def domain(offset=0, limit=-1)
      ResultSet.new(nil, @domain_nodes.dup)
    end
  
    def restricted_image(restriction, options= {})
      items_set = Set.new(restriction.map{|node| node.item})
      ResultSet.new(nil, Set.new((@domain_nodes.select{|dnode| items_set.include? dnode.item}).map{|dnode| dnode.children}.flatten))
    end
  
    def restricted_domain(restriction, options = {})
      items_set = Set.new(restriction.map{|node| node.item})
      intersected_image = @domain_nodes.map{|dnode| dnode.children}.flatten.select{|img_node| items_set.include? img_node.item}
      ResultSet.new(nil, Set.new(intersected_image.map{|img_node| img_node.parent}))
    end
    
    def group_by_domain_hash(domain_nodes_list)
      image_by_domain_hash = {}
      hash_keys = (@domain_nodes & domain_nodes_list)
      hash_keys.each do |key_node|
        image_by_domain_hash[key_node] = key_node.children
      end

      image_by_domain_hash
    end
    
    def group_by_image(nodes)
      groups = {}

      grouped_nodes = @domain_nodes & nodes
      grouped_nodes.each do |node|
        node.children.each do |child|
          if !groups.has_key? child.item
            groups[child.item] = Xplain::Node.new(child.item)
          end
          groups[child.item] << Xplain::Node.new(node.item)
        end
      end
      ResultSet.new(nil, groups.values)
    end
  
  end
end