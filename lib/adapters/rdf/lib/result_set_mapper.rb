module Xplain::RDF
  module ResultSetMapper
    def result_set_count
      rs = execute("SELECT distinct ?s where {?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://tecweb.inf.puc-rio.br/xplain/ResultSet>}")
      rs.size
    end
    
    #TODO preventing saving sets already save and unmodified
    def result_set_save(result_set, flush_extension=false)
      
      #TODO save title
      #TODO save annotations
      namespace = "http://tecweb.inf.puc-rio.br/xplain/"
      if !(result_set.id =~ URI::regexp)
        result_set.id = "#{@xplain_ns.uri}#{result_set.id}"
      end

      
      result_set_uri = "<#{result_set.id}>"
      result_set_type_uri = "<#{namespace + result_set.class.to_s.split("::").last}>"
      insert_rs_query = "INSERT DATA{ " + result_set_uri + " <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " + result_set_type_uri + "."
      insert_rs_query << "#{result_set_uri} <http://purl.org/dc/terms/title> \"#{result_set.title}\". "
      
      intention_parser = DSLParser.new
      if result_set.intention
        insert_rs_query << "#{result_set_uri} <#{namespace}intention> \"#{intention_parser.to_ruby(result_set.intention).gsub("\"", '\"').gsub("\n", "\\n")}\". "
      end
      
      result_set.annotations.each do |note|
        insert_rs_query << "#{result_set_uri} <#{namespace}note> \"#{note}\". "
      end
       
      insert_rs_query << "}"
      execute_update(insert_rs_query, content_type: content_type)
      
      # if !result_set.is_a? Xplain::RemoteSet
        query = "INSERT DATA{ "
        triples = ""
        index = 0

        result_set.each{|node| triples << generate_insert(index += 1, node, result_set)}
        
        temp_file_name = "temp#{SecureRandom.uuid}.nt"
        
        if !Dir.exist?("./tmp")
          Dir.mkdir("./tmp")
        end
        
        File.open("./tmp/#{temp_file_name}", "w"){|f| f.write(triples)}

        if self.url
          uri = URI(self.url)
          http = Net::HTTP.new(uri.host, uri.port)
          header = {'Content-Type': 'text/plain'}
          request = Net::HTTP::Post.new(uri.request_uri, header)
          request.body = File.read("./tmp/#{temp_file_name}")
          response = http.request(request)
          File.delete("./tmp/#{temp_file_name}")
          
          if response.code != "200"
            raise "Could not insert the result set #{result_set.title} into the repository!"
          end
        else
          query << triples
          query << "}"
          
          execute_update(query, content_type: content_type)
        end

        
        
        
        
        # execute_update(query, content_type: content_type)
      # end
      
    end
    
    def result_set_find_by_node_id(node_id)
      rs_query = "SELECT ?o WHERE{<#{@xplain_ns.uri + node_id}> <#{@xplain_ns.uri}included_in> ?o}"
      rs_uri = nil
      @graph.query(rs_query).each do |solution|
        rs_uri = solution[:o].to_s
      end
      if rs_uri
        [result_set_load(rs_uri)]
      end
    end
    
    def result_set_delete_all
      result_set_load_all.each{|rs| result_set_delete rs}
    end
    
    def result_set_delete(result_set, options={:cascade => false})
      #TODO the index triples may not be removed if the ordering of the items change for some reason. Remove all oh them!
      namespace = "http://tecweb.inf.puc-rio.br/xplain/"
      result_set_uri = "<#{result_set.id}>"
      result_set_type_uri = "<#{namespace + "ResultSet"}>"
      insert_rs_query = "DELETE DATA{ " + result_set_uri + " <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " + result_set_type_uri + "."
      insert_rs_query << "#{result_set_uri} <http://purl.org/dc/terms/title> \"#{result_set.title}\". "
      intention_parser = DSLParser.new
      if result_set.intention
        insert_rs_query << "#{result_set_uri} <#{namespace}intention> \"#{intention_parser.to_ruby(result_set.intention).gsub("\"", '\"').gsub("\n", "\\n")}\". "
      end
      
      result_set.annotations.each do |note|
        insert_rs_query << "#{result_set_uri} <#{namespace}note> \"#{note}\". "
      end
       
      insert_rs_query << "}"
      execute_update(insert_rs_query, content_type: content_type)
      query = "DELETE DATA{ "  
      index = 0  
      result_set.each do |node|
         
        query << generate_insert(index += 1, node, result_set)
      end      
      query << "}"
      execute_update(query, content_type: content_type)
      
      if options[:cascade]
        select = "select ?s ?p ?o where{?s ?p ?o. VALUES ?s{"
        server = result_set.intention.server
        result_set.each do |n|
          item_uri = Xplain::Namespace.expand_uri n.item.id
          select << "<#{item_uri}> "
        end
        select << "}}"
        
        delete_data = ""        
        s_array = server.execute(select)
        
        s_array.each do |s|
          delete_data << "<#{s[:s].to_s}> <#{s[:p].to_s}> "
          
          if s[:o].literal?
            delete_data << "\"#{s[:o].to_s}\""
          else
            delete_data << "<#{s[:o].to_s}>"
          end
          delete_data << ". "
        end
        
        delete_data =  "delete data{#{delete_data}}"
        server.execute_update(delete_data, content_type: content_type)
        
        select = "select ?s ?p ?o where{?s ?p ?o. VALUES ?o{"
        server = result_set.intention.server
        result_set.each do |n|
          item_uri = Xplain::Namespace.expand_uri n.item.id
          select << "<#{item_uri}> "
        end
        select << "}}"
        
        delete_data = ""
        s_array = server.execute(select)
         
        s_array.each do |s|
          delete_data << "<#{s[:s].to_s}> <#{s[:p].to_s}> "
          delete_data << "<#{s[:o].to_s}>"
          delete_data << ". "
        end
        
        delete_data =  "delete data{#{delete_data}}"
        
        server.execute_update(delete_data, content_type: content_type)
      end
    end
    
    #TODO document options
    def result_set_load_all(options={})
      query = "SELECT ?s ?i WHERE{?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}ResultSet>. OPTIONAL{?s <#{@xplain_ns.uri}intention> ?i} "
      if options[:exploration_only]
        query << " FILTER NOT EXISTS {FILTER (regex(?i, \"visual: \s*true\",\"i\")) }." 
      end
      query << "}"
  
      solutions = @graph.query(query)
      set_id_list = []
      solutions.each do |sol|
        set_id_list << sol[:s].to_s
      end
      set_id_list.map{|id| result_set_load(id)}
    end
    
    def build_node(node_data, server)
      
      id, node_text, index, item, item_type, datatype = node_data.values_at(:id, :node_text, :index, :item, :item_type, :datatype)

      if item_type == "Xplain::Literal"        
        item = build_literal node_text, datatype
      else
        item = build_item item, item_type
      end
      
      item.text ||= node_text
      
      if server
        item.server = server
        #TODO if the server cannot be loaded, try loading from the session or raise an exception
      end
      
      
      Xplain::Node.new(id: id, item: item)
    end
    
    def result_set_load(rs_id, load_extension=true, alternative_server = nil)
      #TODO implement for literal items
      if !(rs_id =~ URI::regexp)
        rs_id = "#{@xplain_ns.uri}#{rs_id}"
      end
      result_set_uri = "<#{rs_id}>"
      
      result_set_query = "SELECT ?title ?note ?intention ?class where{#{result_set_uri} <http://purl.org/dc/terms/title> ?title. #{result_set_uri} <#{@rdf_ns.uri}type> ?class. OPTIONAL{#{result_set_uri} <#{@xplain_ns.uri}note> ?note}. OPTIONAL{#{result_set_uri} <#{@xplain_ns.uri}intention> ?intention }.}"
      title = ""
      intention = ""
      notes = Set.new
      
      klass = "Xplain::ResultSet"
      @graph.query(result_set_query).each do |solution|
        title = solution[:title].to_s
        if solution[:note]
          notes << solution[:note].to_s
        end
        intention = solution[:intention].to_s
        klass = "Xplain::" + solution[:class].to_s.split("/").last
      end
      
      if !(klass == "Xplain::RemoteSet")

        query = "prefix xsd: <#{@xsd_ns.uri}> 
        SELECT *
        WHERE{
          ?node <#{@xplain_ns.uri}included_in> #{result_set_uri}.
          ?node <#{@xplain_ns.uri}index> ?nodeIndex.
          
          OPTIONAL{
            ?node <#{@xplain_ns.uri}has_item> ?item. 
            ?item <#{@xplain_ns.uri}item_type> ?itemType. 
            OPTIONAL{?item <#{@xplain_ns.uri}has_server> ?server}
          }.

          OPTIONAL{ ?node <#{@xplain_ns.uri}has_text> ?nodeText}.
          
          OPTIONAL{
            ?node <#{@xplain_ns.uri}children> ?child. 
            ?child <#{@xplain_ns.uri}index> ?childIndex.
            ?child <#{@xplain_ns.uri}has_item> ?childItem.  
            OPTIONAL{?childItem <#{@xplain_ns.uri}item_type> ?childType}. 
            OPTIONAL{?childItem <#{@xplain_ns.uri}has_server> ?childServer}
          }.

        } ORDER BY xsd:integer(?nodeIndex) xsd:integer(?childIndex)"
        
        nodes = []
        nodes_hash = {}
        
        
        puts "-------RS QUERY---------"
        puts query
        items = Set.new
        servers_hash = Xplain::DataServer.load_all().map{|s| [s.url, s]}.to_h
        
        @graph.query(query).each do |solution|
          next if !solution[:node] || !solution[:item]
          
          if !nodes_hash.has_key? solution[:node].to_s
            node_data = {
              id: solution[:node].to_s, 
              node_text: solution[:nodeText].to_s,
              index: solution[:nodeIndex].to_s.to_i, 
              server: solution[:server].to_s, 
              item: solution[:item], 
              item_type: solution[:itemType].to_s,
              datatype: solution[:datatype].to_s
            }
            node = build_node(node_data, servers_hash[solution[:server].to_s])
            
            if !node.item.is_a? Xplain::Literal
              items << node.item
            end
            nodes_hash[node.id] = node
          end

          node = nodes_hash[solution[:node].to_s]
          
          if solution[:child]
            if !nodes_hash.has_key? solution[:child].to_s
              node_data = {
                id: solution[:child].to_s, 
                node_text: solution[:childText].to_s, 
                index: solution[:childIndex].to_s.to_i, 
                server: solution[:childServer].to_s, 
                item: solution[:childItem], 
                item_type: solution[:childType].to_s, 
                datatype: solution[:child_datatype].to_s
              }
              child_node = build_node(node_data, servers_hash[solution[:childServer].to_s])
              if !child_node.item.is_a? Xplain::Literal
                items << child_node.item
              end
              nodes_hash[child_node.id] = child_node
            end

            child_node = nodes_hash[solution[:child].to_s]
            
            if !child_node.item.is_a? Xplain::Literal
              items << child_node.item
            end
            node << child_node
          end
        end
        set_types(items)
        
        first_level = Set.new(nodes_hash.values.uniq.select{|n| !n.parent})
        
      end

      if !intention.to_s.empty?
        puts "------LOADED INTENTION------"
        puts intention.to_s
        intention_desc = eval(intention)
        intention_desc.server = alternative_server if alternative_server
      end

      eval(klass).new(id: rs_id, nodes: first_level, intention: intention_desc, title: title, notes: notes.to_a)
      
    end
    
    def set_types(items)
      return if items.empty?

      items_hash = {} 
      items.each do |item|
        items_hash[Xplain::Namespace.expand_uri(item.id)] = item
      end 

      uris = items.map{|i| "<#{Xplain::Namespace.expand_uri(i.id)}>"}.join(" ")
      values_s = "VALUES ?s {#{uris}}."
      query = "SELECT ?s ?t WHERE {?s <#{@rdf_ns.uri}type> ?t. #{values_s}}"
      puts query
      @graph.query(query).each_solution do |s|
      
        type = Xplain::Type.new(Xplain::Namespace.colapse_uri(s[:t].to_s))
        items_hash[s[:s].to_s].types << type
      end
      items_hash.values.each{|item| item.types.delete(Xplain::Type.new("rdfs:Resource")) if item.types.size > 1}

    end

    def set_items_texts(items)
      items_hash = {} 
      items.each do |item|
        if !items_hash.has_key? item.id
          items_hash[item.id] = []
        end
        items_hash[item.id] << item
      end  
      values_s = "VALUES ?s{ " << items_hash.keys.map{|id| "<#{id}>"}.join(" ") << "}"
      
      values_p = "VALUES ?p{ " << items.map{|item| "<#{Xplain::Namespace.expand_uri(item.text_relation)}>"}.uniq.join(" ") << "}"
      query = "SELECT * WHERE{?s ?p ?text. #{values_s}. #{values_p}}"
      puts "-------TEXT QUERY---------"
      puts query
      @graph.query(query).each_solution do |solution|
        items_hash[solution[:s].to_s].each{|item| item.text = solution[:text].to_s}
      end
    end
    
    #TODO Document options: exploration_only
    def result_set_find_by_session(session, options={})
      rs_uri_query = "SELECT ?o ?i WHERE{<#{Xplain::Namespace.expand_uri(session.id)}> <#{@xplain_ns.uri}contains_set> ?o.  OPTIONAL{?o <#{@xplain_ns.uri}intention> ?i}"
      if options[:exploration_only]
        rs_uri_query << " BIND (COALESCE(?i, \"no intention\") as ?i) FILTER NOT EXISTS {FILTER (regex(str(?i), \"visual: \s*true\",\"i\")) }." 
      end
      rs_uri_query << "}"
  
      result_set_ids = []
      @graph.query(rs_uri_query).each_solution do |solution|
        result_set_ids << solution[:o].to_s
      end
      
      results = result_set_ids.map do |id| 
        rs = result_set_load(id)
        session
        
        if rs.intention
          rs.intention.session = session
          
        end
        rs 
      end
      session.setup_result_sets(results)
      
      results
    end

    
    #private
    def generate_insert(index, node, result_set)
      if !node.id
        node.id = @xplain_ns.uri + SecureRandom.uuid
      end
      insert_stmt = "<#{node.id}> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Node>.\n"
      included_in_pred = "<#{@xplain_ns.uri}included_in>"
      result_set_uri = "<" + result_set.id + ">"
      insert_stmt += "<#{node.id}> #{included_in_pred} #{result_set_uri}.\n"
      item_uri = ""
      if node.item.is_a? Xplain::Literal
        literal_id = SecureRandom.uuid
        item_uri = "<#{@xplain_ns.uri}literal/#{literal_id}>"
        insert_stmt += "#{item_uri} <#{@xplain_ns.uri}datatype> \"#{node.item.datatype}\".\n"
      else
        item_uri = parse_item(node.item)
      end
      
      
      
      insert_stmt += "<#{node.id}> <#{@xplain_ns.uri}has_item> #{item_uri}.\n"
      
      insert_stmt += "#{item_uri} <#{@xplain_ns.uri}item_type> \"#{node.item.class.name}\".\n"
      
      if !node.item.is_a? Xplain::Literal 
        type_stmts = node.item.types.map{|t| "#{item_uri} <#{@rdf_ns.uri}type> <#{Xplain::Namespace.expand_uri(t.id)}>.\n"}
        insert_stmt += type_stmts.join("") if !type_stmts.empty?
      end
      
      
      insert_stmt += "<#{node.id}> <#{@xplain_ns.uri}has_text>  \"#{node.item.text.gsub('"', '\"')}\".\n"
      

      if node.item.server
        insert_stmt += "#{item_uri} <#{@xplain_ns.uri}has_server> <#{node.item.server.id}>.\n"
      end

      insert_stmt += "<#{node.id}> <#{@xplain_ns.uri}index> \"#{index}\"^^<http://www.w3.org/2001/XMLSchema#integer>.\n"
      
      child_index = 0
      node.children.each do |child|
        insert_stmt += generate_insert(child_index += 1, child, result_set)
        child_uri = "<#{child.id}>"
        insert_stmt += "<#{node.id}> <#{@xplain_ns.uri}children> #{child_uri}.\n"
      end
      puts "INSERT: " << insert_stmt
      insert_stmt
    end
  end
end