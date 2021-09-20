module Xplain
  class Node
    attr_accessor :id, :item, :parent_edges, :children_edges, :annotations
    class << self
      def uniq_by_item(nodes)
        nodes.map{|n| [n.item, n]}.to_h.values
      end
      def from_h(node_hash)
        item = Xplain::Item.create(node_hash[:id], node_hash[:text].to_s, node_hash[:server], eval(node_hash[:type]))

        node =  new(
          id: node_hash[:node], 
          item: item, 
          children: node_hash[:children].to_a.map{|c|from_h(c)}
        )
        node        
      end
    end
    
    def initialize(params = {})
      @children_edges = Set.new
      
      @annotations = params[:notes] || []
      if item.is_a? Xplain::Node
        raise InvalidArgumentError("The item cannot be a Xplain::Node!");
      end
      @item = params[:item]
      @id = params[:id]
      @parent_edges = Set.new
      self.children = params[:children] if params[:children]
    end
    
    def result_set
      parent_node = self
      while (!parent_node.parent.nil?)
        parent_node = parent_node.parent
      end
      return parent_node
    end

    def all_nodes
      result_nodes = self.children
      self.children.each do |child|
        result_nodes += child.all_nodes
      end
      result_nodes
    end

    
    def <=>(other_node)
      self.item <=> other_node.item
    end
  
    
    def annotate(annotation)
      @annotations << annotation
    end
    
    def parents
      Set.new(@parent_edges.map{|edge| edge.origin})
    end
    
    def parent
      parent_node = nil
      if(@parent_edges.first)
        parent_node = @parent_edges.first.origin
      end
      parent_node
    end
    
    def same_branch(node)
      self.ancestors.shift == node.ancestors.shift
    end
    
    def remove_child(child)
      @children_edges.delete_if{|edge| edge.target == child}
    end
    
    def ancestors
      ancestors_list = []
      ancestor = parent
      while(ancestor) do
        ancestors_list << ancestor
        ancestor = ancestor.parent
      end
      ancestors_list
    end
    
    def accept(visitor)
      visitor.visit(self)
    end
    
    def add_parent(parent_node)
      @parent_edges << Edge.new(parent_node, self)
    end
    
    def children=(children_set)
      if children_set
        @children_edges = children_set.map do |child| 
          child.add_parent self
          Edge.new(self, child)
        end 
      end
    end
    
    def append_children(children_set)
      @children_edges += children_set.map do |child| 
        child.parent = self
        Edge.new(self, child)
      end
    end
    
    def parent_edge=(parent_edge)
      @parent_edges << parent_edge
    end
    
    def parent=(parent)
      @parent_edges = []
      add_parent parent
    end
    
    def children
      @children_edges.map{|edge| edge.target}
    end
    
    #TODO Deprecate
    def get_level_relation(level)
      Xplain::ResultSet.new(nodes: get_level(level))
    end
    
    def leaf?
      children.empty?
    end
    
    def copy
      node_copy = Xplain::Node.new(item: self.item)
  
      node_copy.children_edges = self.children_edges.map{|edge| Edge.new(node_copy, edge.target.copy, edge.annotations)}
      node_copy.children.each{|child| child.parent_edge = Edge.new(node_copy, child)}
      node_copy
    end
    
    def each_level(&block)
      levels = []
  
      current_level = [self]
  
      while !current_level.empty?
        levels << current_level
        if block_given?
          yield(current_level)
        end
        current_level = current_level.map{|li| li.children}.flatten
  
      end
      levels
    end
  
    def count_levels
      number_of_levels = ancestors.size
      each_level{number_of_levels+=1}
      number_of_levels
    end
  
    def get_level(level, parents_restriction=[], children_restriction= [], offset=0, limit=-1)
      level_items = []
      current_level = ancestors.size
      each_level{|current_level_items| level_items = current_level_items if ((current_level += 1) == level)}
      if(limit > 0 && offset >= 0 )
        level_items = level_items[offset..(offset+limit)-1]
      end
      # binding.pry
      level_items
    end
    
    
    def find(item_to_find)
      if self.item == item_to_find
        return self
      end
      each_level do |level_nodes| 
        selected_nodes = level_nodes.select{|node| node.item == item_to_find}
        if !selected_nodes.empty?
          return selected_nodes.first
        end
      end
      return nil
    end
    
    def last_level
      each_level.last
    end
    
    def <<(child)
      @children_edges << Edge.new(self, child)
      child.add_parent self
    end
    
    
    def to_s
      
      "N " + @item.to_s
    end
    
    def to_hash_children_node_by_item
      hash_children_node_by_item = {} 
      children.each do |child|
        
        if !hash_children_node_by_item.has_key? child.item
          hash_children_node_by_item[child.item] = []
        end
        hash_children_node_by_item[child.item] << child
      end
      hash_children_node_by_item
      
    end
    
    def children_items
      children.map{|node| node.item}    
    end
    
    def breadth_first_search(all_occurrences=true, &block)
      nodes_found = []
      nodes_to_search = children
      while !nodes_to_search.empty?
        nodes_found += nodes_to_search.select do |node|
          yield(node)
        end
        
        if !nodes_found.empty? && !all_occurrences
          return [nodes_found.first]
        end
        
        nodes_to_search = nodes_to_search.map{|node| node.children}.flatten
      end
      nodes_found
  
    end
    
    def inspect
      inspect_string = ""
      
      inspect_string << self.to_s + "\n   => ["+ @children_edges.map{|c| c.to_s }.join(", ") + "]"
      inspect_string
    end
    
    def to_h()
      node_hash = {
        node: @id.to_s,        
      }


      children_hashes = self.children.map do |c|
        c.to_h
      end
      
      node_hash.merge! @item.to_h
      node_hash[:children] = children_hashes
      # binding.pry
      return node_hash

    end
    alias == eql?

  end

end