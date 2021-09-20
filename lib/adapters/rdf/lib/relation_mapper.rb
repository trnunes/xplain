module Xplain::RDF
  module RelationMapper
    
    attr_accessor :limit, :offset
    
    def self.included klass
       klass.class_eval do
         include SPARQLHelper
       end
    end

    def path_relation_save(path_relation)
=begin      
INSERT DATA{        
      <http://tecweb.inf.puc-rio.br/xplain/path_1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://tecweb.inf.puc-rio.br/xplain/PathRelation>.
      <http://tecweb.inf.puc-rio.br/xplain/path_1> <http://purl.org/dc/terms/title> "path test 1".
      <http://tecweb.inf.puc-rio.br/xplain/path_1> <http://tecweb.inf.puc-rio.br/xplain/intention> "Xplain::PathRelation.new(text: \"path test 1\", relations: [Xplain::SchemaRelation.new(id: \"cito:cites\", inverse: true), Xplain::SchemaRelation.new(id: \"prismstandard:publicationDate\")])"


}
=end  
      text = path_relation.text
      uri = "<#{@xplain_ns.uri + text.gsub(" ", "_")}>"
      type_triple = "#{uri} <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}PathRelation>"
      name_triple = "#{uri} <http://purl.org/dc/terms/title> \"#{text}\""
      #TODO move the intention generation to Xplain::PathRelation.to_ruby
      intention = "\"Xplain::PathRelation.new(text: \\\"#{text}\\\", relations: [#{path_relation.map{|relation| parse_schema_relation relation}.join(", ")}])\""
      eval(eval(intention))
      intention_triple = "#{uri} <#{@xplain_ns.uri}intention> #{intention}"
      insert_query = "INSERT DATA{"
      insert_query << type_triple
      insert_query << ". #{name_triple}"
      insert_query << ". #{intention_triple}"       
      insert_query << "}"
      rs = execute_update(insert_query, content_type: content_type)
    end    

    def path_relation_load_all
      query = "SELECT ?s ?p ?o where{?s ?p ?o. ?s <#{@rdf_ns.uri}type> <http://tecweb.inf.puc-rio.br/xplain/PathRelation>}"
      path_relation_list = []
      execute(query).each do |sol| 
        if sol[:p].to_s.include? "intention"

          path_relation_list << eval(sol[:o].to_s)          
        end
      end

      path_relation_list
    end

    #TODO very similar code with DSLParser#parse_schema_relation
    def parse_schema_relation(schema_relation)
      "Xplain::SchemaRelation.new(id: \\\"#{schema_relation.id}\\\", inverse: #{schema_relation.inverse})"
    end

  
  
    def image(relation, offset = 0, limit = -1, crossed=false, &block)
      items = []
      values_stmt = ""

      if relation.inverse? && !crossed
        return domain(relation, offset, limit, true, &block)
      end
          
      query_stmt = "SELECT distinct ?o where{#{values_stmt} ?s <#{Xplain::Namespace.expand_uri(relation.id)}> ?o}"
      query_stmt = insert_order_by_subject(query_stmt)
      
      if limit > 0
        query_stmt << " OFFSET #{offset} LIMIT #{limit}"
      end
      
      Xplain::ResultSet.new nodes: to_nodes(get_results(query_stmt, relation))
    end
  
    def domain(relation, offset=0, limit=-1, crossed=false, &block)
      items = []
      values_stmt = ""
      if relation.inverse? && !crossed
        return image(relation, offset, limit, true, &block) 
      end
      query_stmt = "SELECT ?s ?o where{#{values_stmt} #{path_clause(relation)} #{path_clause_as_subselect(relation, values_stmt, "?s", limit, offset)}.}"
      query_stmt = insert_order_by_subject(query_stmt)
      
      Xplain::ResultSet.new nodes: to_nodes(get_results(query_stmt, relation))
    end
    
    #TODO CORRECT

    def restricted_image_old(relation, restriction, options={})
      if relation.nil?
        raise "Cannot compute restricted image of a null relation!"
      end
      if @ignore_literal_queries
        return Xplain::ResultSet.new() if restriction.first.item.is_a? Xplain::Literal
      end
      
      restriction_items = restriction.map{|node|node.item}.uniq || [] 
      
      image_filter_items = options[:image_filter] || []
      
      results_hash = {}      
      where_clause = ""
      relation_uri = parse_relation(relation)
      paginate(restriction_items, @items_limit).each do |page_items|
        
        if(relation.is_a?(Xplain::PathRelation) && relation.size > 1)
    
          where_clause = "{#{path_clause(relation)}}. #{values_clause("?s", page_items)} #{values_clause("?o", image_filter_items)} #{mount_label_clause("?o", page_items, relation)}"
        else
          where_clause = "#{values_clause("?s", page_items)} {#{path_clause(relation)}}. #{mount_label_clause("?o", page_items, relation)} #{values_clause("?o", image_filter_items)}"
        end
        
        query = "SELECT ?s ?o ?textPropo ?lo ?t"
        if options[:group_by_domain]
          label_relations = page_items.map{|item| item.text_relation}
            .select{|text_relation| Xplain::Namespace.colapse_uri(text_relation) != "xplain:has_text"}
            .compact.uniq
          query << " ?ls ?textProps"
          where_clause << " #{optional_label_where_clause("?s", label_relations)}"
          
        end
        where_clause << types_clause("?o")
        
        query << " where{#{where_clause} }"
        query = insert_order_by_subject(query)
      
        results_hash.merge! get_results(query, relation)
        
      end
      result_nodes = hash_to_graph(results_hash)
      result_set =  Xplain::ResultSet.new nodes: result_nodes
      if !options[:group_by_domain] && !result_set.empty?
        image = result_set.last_level
        if !image.first.is_a? Xplain::Literal
          image = Set.new image
        end
        result_set = Xplain::ResultSet.new(nodes: image)
      end
      
      result_set
    end
    
    

    def restricted_image(relation, restriction, options={})
      result_set  = Xplain::ResultSet.new()
      if relation.nil?
        raise "Cannot compute restricted image of a null relation!"
      end
      image_filter_items = options[:image_filter] || []
      where_clause = ""
      restriction_items = restriction.map{|node| node.item}.uniq || []
      entities = []
      relation_uri = parse_relation(relation)
      servers_hash = {}
      results_hash = {}
      preserve_input = options[:preserve_input]
      preserve_input = true if preserve_input.to_s.empty?

      paginate(restriction_items, @items_limit).each do |page_items|
        # binding.pry
        page_items.each do |item|
          if !item.server
            raise "Item \"#{item.id}\", \"#{item.text}\" does not contain a server!"
          end

          if !servers_hash.has_key? item.server
            servers_hash[item.server] = []            
          end

          servers_hash[item.server] << item
        end
        servers_hash.entries.each do |server, server_items|
          if relation.size > 1
            where_clause = "{#{path_clause(relation)}}. #{values_clause("?s", page_items)} #{values_clause("?o", image_filter_items)} #{mount_label_clause("?o", page_items, relation)}"
          else
            where_clause = "#{values_clause("?s", page_items)} {#{path_clause(relation)}}. #{mount_label_clause("?o", page_items, relation)} #{values_clause("?o", image_filter_items)}"
          end
          
          query = "SELECT ?s ?o ?textPropo ?lo ?t"
          
          if options[:group_by_domain]
            label_relations = page_items.map{|item| item.text_relation}
              .select{|text_relation| Xplain::Namespace.colapse_uri(text_relation) != "xplain:has_text"}
              .compact.uniq
            query << " ?ls ?textProps"
            where_clause << " #{optional_label_where_clause("?s", label_relations)}"
            
          end
          where_clause << types_clause("?o")
          
          query << " where{#{where_clause} }"
          query = insert_order_by_subject(query)
          binding.pry if options[:debug]
          
          results_hash.merge! get_results(query, relation, server)
          if preserve_input
            server_items.each do|item| 
              if !results_hash.has_key? item
                results_hash[item] = []
              end

            end
          end

        end

      end
      result_nodes = hash_to_graph(results_hash)
      result_set =  Xplain::ResultSet.new nodes: result_nodes
      if !options[:group_by_domain] && !result_set.empty?
        image = result_set.last_level
        if !image.first.is_a? Xplain::Literal
          image = Set.new image
        end
        result_set = Xplain::ResultSet.new(nodes: image)
      end
      
      binding.pry if options[:debug]
      result_set
    end
    #TODO CORRECT
    def restricted_domain(relation, restriction, options)
      if relation.nil?
        raise "Cannot compute restricted domain of a null relation!"
      end
      if @ignore_literal_queries
        return Xplain::ResultSet.new() if restriction.first.item.is_a? Xplain::Literal
      end
      
      if relation.meta?
        result_set =  
          if relation.inverse?
            self.send((relation.id + "_restricted_image").to_sym, restriction, options)
          else
            self.send((relation.id + "_restricted_domain").to_sym, restriction, options)
          end
        
        return result_set          
      end
      
      restriction_items = restriction.map{|node|node.item}.uniq || [] 
      
      domain_items = options[:domain_filter] || []
      results_hash = {}
      servers_hash = {}
      
      paginate(restriction_items, @items_limit).each do |page_items|
        page_items.each do |item|
          if !item.server
            raise "Item \"#{item.id}\", \"#{item.text}\" does not contain a server!"
          end

          if !servers_hash[item.server]
            servers_hash[item.server] = []
          end
          servers_hash[item.server] << item
        end
        servers_hash.entries.each do |server, items|
          label_clause = mount_label_clause("?s", page_items, relation)
    
          where = "#{path_clause(relation)}. #{label_clause}"
          if(!domain_items.empty?)
            where = "#{values_clause("?s", domain_items)}" << where
          end

          query = "SELECT ?s ?o ?textProp ?ls WHERE{#{where}  #{values_clause("?o", page_items)} #{path_clause_as_subselect(relation, values_clause("?o", page_items) + values_clause("?s", domain_items), "?s", options[:limit], options[:offset])}}"
          query = insert_order_by_subject(query)
          puts query
          results_hash.merge! get_results(query, relation, server)

        end
      
      end
      Xplain::ResultSet.new(nodes: hash_to_graph(results_hash))
    end
  
      
    def find_relations(items)
      results = Set.new
      servers_hash = {}
      paginate(items, @items_limit).each do |page_items|
        page_items.each do |item|
          if !servers_hash.has_key? item.server
            servers_hash[item.server] = []
          end
          if !item.server
            raise "Item \"#{item.id}\", \"#{item.text}\" does not contain a server!"
          end

          servers_hash[item.server] << item
        
        end        

        servers_hash.entries.each do |server, server_items|
          are_literals = !server_items.empty? && server_items[0].is_a?(Xplain::Literal)    
          if(are_literals)
            query = "SELECT distinct ?pf WHERE{ {VALUES ?o {#{server_items.map{|i| convert_literal(i.item)}.join(" ")}}. ?s ?pf ?o.}}"
          else
            query = "SELECT distinct ?pf ?pb WHERE{ {VALUES ?o {#{server_items.map{|i| "<" + i.item.id + ">"}.join(" ")}}. ?s ?pf ?o.} UNION {VALUES ?s {#{server_items.map{|i| "<" + i.item.id + ">"}.join(" ")}}. ?s ?pb ?o.}}"
          end

          execute(query).each do |s|
            if(!s[:pf].nil?)
              results << Xplain::SchemaRelation.new(Xplain::Namespace.colapse_uri(s[:pf].to_s), true, self)
            end

            if(!s[:pb].nil?)
              results << Xplain::SchemaRelation.new(Xplain::Namespace.colapse_uri(s[:pb].to_s), false, self)
            end
          end

        end

          

      end

      results.sort{|r1, r2| r1.to_s <=> r2.to_s}
      
    end
    
    ###
    ### Meta relation handler methods
    ###
    
    def relations_image(options = {}, &block)
      query = "SELECT DISTINCT ?p WHERE { ?s ?p ?o.}"
      relations = []
      execute(query, options).each do |s|
        relation = Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(s[:p].to_s), server: self)      
        relations << relation
      end
      Xplain::ResultSet.new nodes: to_nodes(relations)
    end
    
    ##TODO implement
    def relations_domain(options = {}, &block)
      []
    end
    
    #TODO CORRECT
    def has_type_image(options= {} &block)
      
      query = "SELECT DISTINCT ?class WHERE { ?s a ?class.}"
      classes = []
      
      execute(query, options).each do |s|
        type = Xplain::Type.create(Xplain::Namespace.colapse_uri(s[:class].to_s))
        type.add_server(self)
        classes << type
      end
      
      Xplain::ResultSet.new nodes: to_nodes(classes.sort{|c1,c2| c1.to_s <=> c2.to_s})
    end
    
      
    def relations_restricted_image(restriction, args)
      if @ignore_literal_queries
        return Xplain::ResultSet.new() if restriction.first.item.is_a? Xplain::Literal
      end
      servers_hash = {}

      restriction_items = restriction.map{|node|node.item} || []
      results = Set.new
      are_literals = !restriction_items.empty? && restriction_items[0].is_a?(Xplain::Literal)
      items_hash = {}
      paginate(restriction_items, @items_limit).each do |page_items|
        page_items.each do |item|
          if !servers_hash.has_key? item.server
            servers_hash[item.server] = []
          end
          if !item.server
            raise "Item \"#{item.id}\", \"#{item.text}\" does not contain a server!"
          end

          servers_hash[item.server] << item
        
        end
        servers_hash.entries.each do |server, server_items|
          query = "SELECT distinct ?s ?o ?pf ?pb WHERE{ {{#{values_clause("?o", server_items)}}. ?s ?pf ?o.} UNION {{#{values_clause("?s", server_items)}}. ?s ?pb ?o.}}"
          if(are_literals)
            query = "SELECT distinct ?o ?pf WHERE{ {#{values_clause("?o", server_items)}}. ?s ?pf ?o.}"
          end

          #puts "ITEMS SIZE: #{page_items.size}"
          #File.open("query_logs.txt", "a"){|f| f.write("BEGIN\n" + query + "\nEND")}
          items_hash = server_items.map{|i| [i.id, [i]]}.to_h

          server.execute(query).each do |s|
            relations = items_hash[s[:s].to_s] || items_hash[s[:o].to_s]
            
            if(!s[:pf].nil?)
              relations << Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(s[:pf].to_s), inverse: true)
              
            end

            if(!s[:pb].nil?)
              relations << Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(s[:pb].to_s), inverse: false)
            end


          end
          
        end
      end
      results = items_hash.values.map do |item_relations| 
        Xplain::Node.new(
          item: item_relations[0], 
          children: item_relations[1, item_relations.size].uniq.map{|i| Xplain::Node.new(item: i)}
        ) 
      end

      result_set = Xplain::ResultSet.new nodes: results.sort{|r1, r2| r1.to_s <=> r2.to_s}
      # binding.pry
      result_set
    end
    
    ##TODO implement
    #TODO CORRECT
    def relations_restricted_domain(restriction, args)
      if @ignore_literal_queries
        return Xplain::ResultSet.new() if restriction.first.item.is_a? Xplain::Literal
      end
      
      restriction_items = restriction.map{|node|node.item}.uniq || []
      entities = []
      paginate(restriction_items, @items_limit).each do |page_items|

        query = "SELECT DISTINCT ?s WHERE { #{values_clause("?relation", page_items)} ?s ?relation ?o. }"
        
        execute(query).each do |s|
          entity = Xplain::Entity.create(Xplain::Namespace.colapse_uri(s[:s].to_s))
          # relation.text = s[:label].to_s if !s[:label].to_s.empty?
          entity.server = self
          entities << entity
        end
      end
      Xplain::ResultSet.new nodes: to_nodes(entities)
    end

    #TODO CORRECT
    def has_type_restricted_image(restriction, args)
      if @ignore_literal_queries
        return Xplain::ResultSet.new() if restriction.first.item.is_a? Xplain::Literal
      end

      restriction_items = restriction.map{|node|node.item}.uniq || []
      classes = []
      paginate(restriction_items, @items_limit).each do |page_items|
        query = "SELECT DISTINCT ?class WHERE {#{values_clause("?s", page_items)} ?s a ?class.}"
      
        execute(query).each do |s|
          type = Xplain::Type.new(Xplain::Namespace.colapse_uri(s[:class].to_s))
          type.add_server(self)
          classes << type
        end
      end
      Xplain::ResultSet.new nodes: to_nodes(classes.sort{|r1, r2| r1.to_s <=> r2.to_s})
    end

    #TODO CORRECT
    def has_type_restricted_domain(restriction, args)
      if @ignore_literal_queries
        return Xplain::ResultSet.new() if restriction.first.item.is_a? Xplain::Literal
      end

      restriction_items = restriction.map{|node|node.item}.uniq || []
      
      entities = []
      label_relations = restriction_items.map{|type| Xplain::Visualization.current_profile.label_relations_for(type.id)}.compact.flatten
      label_relations = Xplain::Visualization.current_profile.label_relations_for("rdfs:Resource")
      paginate(restriction_items, @items_limit).each do |page_items|
        query = "SELECT DISTINCT ?s WHERE {#{values_clause("?class", page_items)} ?s a ?class.}"
        execute(query).each do |s|
          entity = Xplain::Entity.create(Xplain::Namespace.colapse_uri(s[:s].to_s))
          entity.add_server(self)
          entity.text_relation = label_relations.first
          entities << entity
        end
      end
      
      set_items_texts(entities)
      
      Xplain::ResultSet.new nodes: to_nodes(entities.sort{|r1, r2| r1.to_s <=> r2.to_s})
    end
    
  end
end

