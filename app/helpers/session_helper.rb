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
  
  def generate_jbuilder(xset)
    json = Jbuilder.new do |set|
      set.set do
      	set.id xset.id
      	set.resultedFrom xset.resulted_from.id if !xset.resulted_from.nil?  
      	set.intention xset.intention
      	set.size xset.size
      	set.extension build_extension(xset.extension, xset)
      end
    end
    json.target!
  end
  
  def build_extension(hash, xset)
    extension = []    
      

    Jbuilder.new do |item| 
      item.array!(hash.keys) do |key|
  	  	if(key.is_a?(Entity) || key.is_a?(Relation))
  		  	item.id key.id
    			item.text key.id
    			item.type key.class.to_s
    			item.inverse key.inverse if key.is_a?(Relation)	
    		else
          puts "ITEM: " << item.inspect
          puts "KEY: " << key.inspect
    			item.id key.to_s
    			item.text key.to_s
    			item.type "Xpair::Literal"
    		end
      	item.set xset.id
      	item.resultedFrom xset.resulted_from.id if !xset.resulted_from.nil? 
      end
    end
  end
  
  def icon_type(item)
    return "literal" if item.is_a?(Fixnum) || item.is_a?(String)
    return "relation" if item.is_a? Relation
    return "entity"
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
  
  def to_json(resourceset)
    json = "{"
    json << "\"id\":\"#{resourceset.id}\", "
    # json << "\"intention\": \"#{resourceset.intention.gsub("\"", "\\\"")}\","
    json << "\"extension\": #{extension_json(resourceset.extension)}"
    json << "}"
    puts "JSON: #{json}"
    json
  end
  
  def extension_json(extension)
    json = "{"
    extension.each do |key, values|
      json << "\"#{key}\":"
      if(values.is_a? Hash)
        json << "{#{extension_json(values)}}"
      else
        json << "[#{values.map{|v| "\"#{v.to_s}\""}.join(", ")}]"
      end
      json << ", "
    end
    json[json.size - 2] = ""
    json << "}"
    json
  end
  
  def to_jstree(xset, render_relations)
    json_items = []
    if render_relations
      items_hash = xset.group_by_domain_and_relation
    else
      items_hash = xset.extension
    end
    puts items_hash.inspect
    items_hash.each do |item, relations_hash|
      json_item = "{"
      
      json_item << "'text': \'#{item.to_s}\',"
      json_item << "'children': ["
      if relations_hash.empty? || !render_relations
        json_item << "{'text': 'Relations'}]"
      else
        relations_hash.each do |relation, values|
          json_item << "{\n"
          json_item << "'text': '#{relation.to_s}',"
          json_item << "'children': ["
          values.each do |v|
            json_item << "{'text': '#{v.to_s}'},"
          end
          json_item << "]"
          json_item << "}"
        end
      end
      json_item << "}"
      json_items << json_item
    end
    return "[#{json_items.join(",")}]"    
  end
  

  
  def entity?(item)
    item.is_a?(Entity)
  end

  
end
