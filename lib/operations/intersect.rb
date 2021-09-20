class Xplain::Intersect

  def get_results(params)
    input_sets = params[:input].to_a.map do |nodes| 
      Xplain::Node.new(children: nodes)
    end.compact
    
    if input_sets.empty?
      return []
    end

    set1 = input_sets.delete_at(0)
    
    input_sets.each do |set2|
      union_nodes = compute(set1, set2)
      set1 = Xplain::Node.new(children: union_nodes)
    end
    
    set1.children
  end

  def compute(input, target)
    parent = Xplain::Node.new()
    node_intersect(input, target, parent)
    return parent.children
  end
  
  def node_intersect(n1, n2, parent)
    n1.children.each do |child_n1|
      n2.children.each do |child_n2|
        if child_n1.item == child_n2.item
          new_child = Xplain::Node.new(item: child_n1.item)
          parent << new_child
          node_intersect(child_n1, child_n2, new_child)
        end
      end
    end
  end
  
end