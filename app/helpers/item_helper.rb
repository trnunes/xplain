module ItemHelper
  
  def css(item)
    if item.is_a? String    
      return ' string'
    elsif item.is_a? Fixnum
      return ' fixnum'
    elsif item.is_a? Item
      return ' resource'
    end
      
    # end
    # if resource.instance_of? RDF::Term
    #   return ' resource '
    # end
    # classes = Array.new
    #
    # resource.class.ancestors.each do |type|
    #   classes <<   type.name.downcase
    # end
    # classes.uniq.join(' ') << ' '
  end
  
  def literal?(item)
    item.is_a?(String) || item.is_a?(Fixnum)    
  end
  def type?(item)
    #Issue a type query by the composition id
    return false
  end
  
  def resources_paginated
    return []
  end
  
  def relations(item)
    ["r1", "r2", "r3"]
  end
  
  def render_resource(resource)
    
       
    return resource.to_s.split("/").last.split("#").last
  end 
  
  def objects(resource, p)
    return ["o1", "o2", "o3"]
  end
end
