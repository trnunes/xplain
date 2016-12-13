module SessionHelper
  def relation?(item)
    return false
  end
  
  def css(item)        
    # if resource.instance_of? String
      return ' resource string'
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
  
  def objects(resource, p)
    return ["o1", "o2", "o3"]
  end
end
