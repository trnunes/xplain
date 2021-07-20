module SPARQLHelper
  
  def convert_literal(literal)
    if literal.datatype
      "\"#{literal.value.to_s}\"^^#{get_literal_type(literal)}"
    else
      if literal.value.to_s.match(/\A[-+]?[0-9]+\z/).nil?
        "\"" + literal.value.to_s + "\""
      else
        if literal.value.to_f.to_s == literal.value.to_s
          literal.value.to_s.to_f
        elsif literal.value.to_s.to_i.to_s == literal.value.to_s
          literal.value.to_s.to_i
        end
      end
    end
  end
  
  def convert_item(item)
    "<#{Xplain::Namespace.expand_uri(item.id)}>"
  end
  
  #TODO Remove this method or specialize to convert only non-path relations
  def convert_path_relation(relation)
    relation.map{|r| "<" + Xplain::Namespace.expand_uri(r.id) + ">"}.join("/")
  end
  
  def path_relation_to_item(path_relation)
    "<" + path_relation.map{|r| Xplain::Namespace.expand_uri(r.id)}.join("/") + ">"
  end
  
  def parse_relation(relation)
    if(relation.is_a? Xplain::PathRelation)
      convert_path_relation relation
    elsif(relation.is_a?(Xplain::Entity) || relation.is_a?(Xplain::Relation))
      convert_item relation
    else
      "<" + relation.to_s + ">"
    end
  end
  
  def parse_item(item)

    if(item.is_a? Xplain::Literal)
      convert_literal(item)
    elsif(item.is_a? Xplain::PathRelation)
      path_relation_to_item(item)
    elsif(item.is_a?(Xplain::Entity) || item.is_a?(Xplain::Relation) || item.is_a?(Xplain::Type))
      convert_item(item)
    else
      item.to_s
    end    
  end
  
  def path_clause(relations, continue_numbering=false)
    relations = [relations] if !(relations.is_a?(Array) || relations.is_a?(Xplain::PathRelation))
    @count = 0 if !continue_numbering || !@count
    svar = "?s"    
    previous_relation = nil
    path_size = relations.size
    current_count = 0
    relations.map do |current_relation|
      current_count += 1
      is_last_relation = (current_count == path_size) 
      if is_last_relation
        ovar = "?o"
      else
        ovar = "?s#{@count += 1}"
      end
      
      if current_relation.inverse?
        ovar, svar = svar, ovar        
        clause = "#{svar} <" + Xplain::Namespace.expand_uri(current_relation.id) + "> #{ovar}"
      else
        clause = "#{svar} <" + Xplain::Namespace.expand_uri(current_relation.id) + "> #{ovar}"
        svar = ovar
      end
      clause
    end.join(".")
  end

  def path_clause_as_subselect(relations, values_clause_stmt="", select_var = "?o", limit=0, offset = 0)
    query = "SELECT distinct #{select_var}{#{values_clause_stmt} #{path_clause(relations)}}"
    "{" + insert_limit_clause(query, limit, offset) + "}"
  end
  
  def insert_limit_clause(query, limit, offset = 0)
    if limit.to_i > 0
      query << " LIMIT #{limit} OFFSET #{offset}"
    end
    query
  end
  
  def insert_order_by_subject(query)
    query << " ORDER BY ?s"
    query
  end

  def label_where_clause(var, label_relations)
    return "" if label_relations.empty?
    label_properties_clause = label_relations.map{|l| "<" << Xplain::Namespace.expand_uri(l) << ">"}.join (" ")
    var_suffix = var.gsub("?", "")
    label_var = "?l" << var_suffix
    
    "{{" + var + " ?textProp#{var_suffix} " + label_var + "}. VALUES ?textProp#{var_suffix}{#{label_properties_clause}}}. "
  end
  
  def values_clause(var, iterable)
    values_clause = ""
    if iterable.size > 0
      values_clause = "VALUES #{var}{" << iterable.each.map{|item| parse_item(item)}.join(" ") << "}."
    end

    values_clause
  end
  
  def types_clause(var)
    "OPTIONAL {#{var} <#{@rdf_ns.uri}type> ?t}."
  end

  
  def mount_label_clause(var, items, relation = nil)
    
    label_clause = ""
    label_relations = []
    
    if relation
      relation_uri = parse_relation(relation) 
      label_relations = try_label_relations_by_relation(relation)
    end
    
    if label_relations.empty?
      if relation
        type = sample_type(items, relation_uri, relation.inverse?)
      else
        type = sample_type(items)
      end      
      label_relations = Xplain::Visualization.current_profile.label_relations_for(type.id)  
    end
    
    clause = optional_label_where_clause var, label_relations
    clause
  
  end
  
  def optional_label_where_clause(var, label_relations)
    return "" if label_relations.empty?
    return "OPTIONAL " + label_where_clause(var, label_relations)
  end
  
  def try_label_relations_by_relation(relation)
    label_relations = []
    if relation.inverse?
      label_relations = Xplain::Visualization.current_profile.domain_label_relations(relation)
    else

      label_relations = Xplain::Visualization.current_profile.image_label_relations(relation)
    end
    label_relations
  end
  
    
  def build_literal(literal, datatype = "")
    xplain_literal = 
    if (literal.respond_to?(:datatype) && !literal.datatype.to_s.empty?)
      Xplain::Literal.new(literal.to_s, literal.datatype.to_s)
    else
      if literal.to_s.match(/\A[-+]?[0-9]+\z/).nil?
        Xplain::Literal.new(literal.to_s)
      else
        Xplain::Literal.new(literal.to_s.to_i)
      end
    end
    if xplain_literal.value.to_s.to_i.to_s == xplain_literal.value.to_s
      xplain_literal.value = xplain_literal.value.to_s.to_i
    end
    if xplain_literal.value.to_f.to_s == xplain_literal.value.to_s
      xplain_literal.value = xplain_literal.value.to_s.to_f
    end
    if !datatype.empty?
      xplain_literal.datatype = datatype
    end

    xplain_literal
  end
  
  def get_literal_type(literal)
    datatype = literal.datatype
    
    case datatype
      when "http://www.w3.org/2001/XMLSchema#string"
        "xsd:string"
      when "http://www.w3.org/2001/XMLSchema#nonPositiveInteger"
        "xsd:nonPositiveInteger"
      when "http://www.w3.org/2001/XMLSchema#negativeInteger"
        "xsd:negativeInteger"
      when "http://www.w3.org/2001/XMLSchema#long"
        "xsd:integer"
      when "http://www.w3.org/2001/XMLSchema#int"
        "xsd:int"
      when "http://www.w3.org/2001/XMLSchema#short"
        "xsd:short"
      when "http://www.w3.org/2001/XMLSchema#double"
        "xsd:double"
      when "http://www.w3.org/2001/XMLSchema#float"
        "xsd:float" 
      when "http://www.w3.org/2001/XMLSchema#date"
        "xsd:date"
      when "http://www.w3.org/2001/XMLSchema#gYear"
        "xsd:gYear"
      when "http://www.w3.org/2001/XMLSchema#datetime"
        "xsd:datetime"
      else
        if literal.value.to_i.to_s == literal.value
          "xsd:int"
        elsif literal.value.to_f.to_s == literal.value
          "xsd:float"          
        else
          "xsd:string"
        end
    end
  end
  
  
  def get_filter_results(query)
    items = {}
    execute(query).each do |solution|
      next if(solution.to_a.empty?)
      subject_id = Xplain::Namespace.colapse_uri(solution[:s].to_s)
      if !items.has_key? subject_id
        item = Xplain::Entity.create(subject_id)
        
        items[subject_id] = item
      end      
    end
    items.values
  end
  
  def build_item(server_item, item_class = "Xplain::Entity")
    #TODO remove duplicated code in get_results function
    if server_item.nil?
      raise "Cannot build a nil item!"
    end
    if(server_item.literal?)
      item = build_literal(server_item)
    else
      if item_class == "Xplain::PathRelation"
        schema_relations = server_item.to_s.split("/http").map do |uri| 
          uri = "http" + uri if !uri.include?("http")
          Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(uri))
        end
        item = Xplain::PathRelation.new(relations: schema_relations)
      elsif item_class == "Xplain::SchemaRelation"
        item = Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(server_item.to_s))
      elsif item_class == "Xplain::Type"
        item = Xplain::Type.create(Xplain::Namespace.colapse_uri(server_item.to_s))
      else
        item = Xplain::Entity.create(Xplain::Namespace.colapse_uri(server_item.to_s))
        item.types = [Xplain::Type.new("rdfs:Resource")]
      end
      item.server = self
    end
    item
  end
  
  def get_results(query, relation)
    result_hash = {}
    items_hash = {}
    execute(query).each do |solution|
      next if(solution.to_a.empty?)
      
      subject_id = Xplain::Namespace.colapse_uri(solution[:s].to_s)
      subject_item = Xplain::Entity.create(subject_id)
      subject_item.text = solution[:ls].to_s
      subject_item.text_relation = Xplain::Namespace.colapse_uri(solution[:textProps].to_s)
      subject_item.add_server(self)
      
      object_id = solution[:o]
      related_item = nil
      if(object_id)
        related_item = 
          if items_hash[object_id]
            items_hash[object_id]
          elsif(object_id.literal?)
            build_literal(object_id)
          else
            related_item = Xplain::Entity.create(Xplain::Namespace.colapse_uri(object_id.to_s))
            related_item.text = solution[:lo].to_s.gsub('"', '\"')
            related_item.text_relation = Xplain::Namespace.colapse_uri(solution[:textPropo].to_s)
            related_item.add_server self
            related_item
          end

          if solution[:t]
            related_item.types << Xplain::Type.new(id: Xplain::Namespace.colapse_uri(solution[:t].to_s))
          elsif !related_item.is_a?(Xplain::Literal) && related_item.types.empty?
            related_item.types << Xplain::Type.new(id: "rdfs:Resource")
          end


      end

      if(!result_hash.has_key? subject_item)
        result_hash[subject_item] = 
          if related_item.is_a? Xplain::Literal
            []
          else
            Set.new
          end
      end
      items_hash[subject_id] = subject_item
      if related_item
        items_hash[object_id] = related_item
        result_hash[subject_item] << related_item
      end
      
    end
    result_hash
  end
end
