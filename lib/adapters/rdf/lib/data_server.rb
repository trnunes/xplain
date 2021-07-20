module Xplain::RDF
  class DataServer < Xplain::DataServer

    include Xplain::RDF::RelationMapper
    include Xplain::RDF::ResultSetMapper
    include Xplain::RDF::SessionMapper
    include Xplain::RDF::ViewMapper

    include Xplain::GraphConverter    
  
    attr_accessor :lookup_service, :graph, :url, :items_limit, :content_type, :api_key, :cache, :filter_intepreter, :record_intention_only, :params, :id
  
  
    def initialize(params = {})
      @params = params
      setup params    
    end
    
    def setup(options)
      @graph = SPARQL::Client.new options[:graph], options
      @named_graph = options[:named_graph]
      if options[:graph].is_a? String
        begin
          @url = URI(options[:graph]).to_s
        rescue Exception => e
        end
      end
      @id = @url || options[:graph].to_s
      @content_type = options[:content_type] || "application/sparql-results+xml"
      @api_key = options[:api_key]
      @cache_max_size = (options[:cache_limit] || 20000).to_i
      @items_limit = (options[:items_limit] || 0).to_i
      @results_limit = (options[:limit] || 5000).to_i
      @record_intention_only = options[:record_intention_only]
      @record_intention_only ||= false
      @ignore_literal_queries = options[:ignore_literal_queries]      
      #Default Namespaces
      Xplain::Namespace.new("owl", "http://www.w3.org/2002/07/owl#")
      Xplain::Namespace.new("rdfs", "http://www.w3.org/2000/01/rdf-schema#")
      @xsd_ns = Xplain::Namespace.new("xsd", "http://www.w3.org/2001/XMLSchema#")
      @rdf_ns = Xplain::Namespace.new("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
      @dcterms = Xplain::Namespace.new("dcterms", "http://purl.org/dc/terms/")
      Xplain::Namespace.new("foaf", "http://xmlns.com/foaf/0.1/")
      Xplain::Namespace.new("rss", "http://purl.org/rss/1.0/")
      @xplain_ns = Xplain::Namespace.new("xplain", "http://tecweb.inf.puc-rio.br/xplain/")
      
      begin
        @graph.query("select * where{ ?s ?p ?o }limit 1")
      rescue Net::HTTP::Persistent::Error => e         
        raise RepositoryConnectionError.new("cannot connect to the repository: " << e.message)
      rescue SocketError => e
        raise RepositoryConnectionError.new("cannot connect to the repository: " << e.message)
      rescue Net::OpenTimeout => e
        raise RepositoryConnectionError.new("Repository timeout: " << e.message)
      end
      if options[:lookup_service]
        @lookup_service = eval(options[:lookup_service]).new(self)
      end

    end

    def size
      @graph.count
    end
    
    def path_string(relations)
      relations.map{|r| "<" << Xplain::Namespace.expand_uri(r.to_s) << ">"}.join("/")
      
    end
    
    def sample_type(items, relation_uri = "", inverse = false)
      types = Xplain::Visualization.current_profile.types
      types.delete("http://www.w3.org/2000/01/rdf-schema#Resource")
      
      retrieved_types = []
      if(types.size > 0 && !items[0].is_a?(Xplain::Literal))
        types_values_clause = "VALUES ?t {#{types.map{|t| "<" + Xplain::Namespace.expand_uri(t) + ">"}.join(" ")}}"
        items_values_clause = "VALUES ?s {#{items[0..5].map{|i| "<" + Xplain::Namespace.expand_uri(i.id) + ">"}.join(" ")}}"
        spo_clause =  ""
        if !relation_uri.to_s.empty?
          if inverse
            spo_clause = "?o #{relation_uri} ?s."
          else
            spo_clause = "?s #{relation_uri} ?o."
          end
        end
        query = "SELECT distinct ?t WHERE{#{items_values_clause}. #{types_values_clause}. #{spo_clause} ?o <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?t}"
        execute(query, content_type: content_type).each do |s|
          retrieved_types << Xplain::Namespace.expand_uri(s[:t].to_s)
        end
       
      end
      
      types_with_vis_properties = (retrieved_types & types)
      types_with_vis_properties.empty? ? Xplain::Type.new("rdfs:Resource") : Xplain::Type.new(types_with_vis_properties.first)
    end
  
    def match_all(keyword_phrase, restriction_nodes=[], offset = 0, limit = 0)
      
      print "LOOKUP SERVICE: #{@lookup_service}"
      if @lookup_service
        return @lookup_service.lookup(keyword_phrase, restriction_nodes, offset, limit)

      end
      retrieved_items = Set.new
      label_relations = Xplain::Visualization.current_profile.label_relations_for("rdfs:Resource")    
      values_p = values_clause("?p", label_relations.map{|id| "<#{id}>"})
      
      filter_clause = "regex(str(?ls), \".*#{keyword_phrase.join(' ')}.*\")" 
      query = "SELECT distinct ?s ?ls WHERE{
        #{values_clause("?s", restriction_nodes.map{|n|n.item})} 
        {?s ?p ?ls}. FILTER(#{filter_clause}).}"
      
  
      if Xplain::Namespace.expand_uri(keyword_phrase.join('').strip) =~ URI::regexp
        url = Xplain::Namespace.expand_uri(keyword_phrase.join('').strip)
        query = "SELECT distinct ?s ?ls WHERE{ VALUES ?s{<#{url}>} #{values_p} {?s ?p ?ls}.}"
      end
      
      puts("KEYWORD QUERY: " + query)
      execute(query, {content_type: content_type, offset: offset, limit: limit}).each do |s|
        item = Xplain::Entity.create(Xplain::Namespace.colapse_uri(s[:s].to_s), s[:ls].to_s)
        item.add_server(self)
        retrieved_items << item
      end
      
      retrieved_items.to_a
    end
    
      
    def each_item(&block)
      items = []
      query = @graph.query("SELECT ?s WHERE{?s ?p ?o.}")
      query.each_solution do |solution|
        item = Xplain::Entity.create(solution[:s].to_s)
        item.add_server(self)  
        items << item      
        block.call(item) if !block.nil?
      end       
      items
    end
       
    def execute(query, options = {})
      if !@named_graph.to_s.empty?
        from_clause = " FROM <#{@named_graph}> WHERE"
        #TODO replace to one call whith OR regex
        query.gsub!("where", from_clause)
        query.gsub!("WHERE", from_clause)
        query.gsub!("Where", from_clause)
      end

      solutions = []
  
      offset = 0
      
      loop do
        limited_query = query + " limit #{@results_limit} offset #{offset}"
        puts "----NEW QUERY-----"
        puts limited_query
        puts "-----------ISSUED ON-----"
        puts @params.inspect
        rs = @graph.query("PREFIX xsd: <http://www.w3.org/2001/XMLSchema#> " << limited_query, options)      
        
        
        solutions += rs.to_a
        
        offset += @results_limit
        break if  (solutions.size < @results_limit || rs.empty?)
      end
        
      print("----------RESULTS SIZE: #{solutions.size}")
      solutions

    end
    
    ###
    ### return: the nodes grouped by the image items of the relation. 
    ### The relation returned is the inverse of _relation arg 
    ###
    
    def aggregate(nodes, relation, aggregate_function, restriction = [])
      if nodes.empty?
        return []
      end
      if relation.nil?
        raise MissingRelationException
      end
      items = nodes.map{|node| node.item}
      values_stmt = "VALUES ?s {#{items.map{|item| "<" + Xplain::Namespace.expand_uri(item.id) + ">"}.join(" ")}}"
      query_stmt = "SELECT ?s (#{aggregate_function}(?o) as ?o) where{#{values_stmt} #{path_clause(relation)} #{values_clause("?o", restriction)} #{path_clause_as_subselect(relation, values_stmt, "?s", limit, offset)}. }"
      query_stmt << " GROUP BY ?s"
      get_results(query_stmt, relation)
    end
    
    def sum(items, relation, restriction = [])
      aggregate(items, relation, "sum", restriction)
    end
    
    def count(items, relation, restriction = [])
      aggregate(items, relation, "count", restriction)
    end
  
    def avg(items, relation, restriction = [])
      aggregate(items, relation, "avg", restriction)
    end
    
    def has_filter_intepreter?
      !@filter_intepreter.nil?
    end
    
    def filter(input_items, filter_expr)
      if input_items.empty?
        return []
      end
      dataset_filter(input_items, filter_expr)
    end

    #TODO Remove  ResultSetMapper#set_items_texts(items)
    def set_items_labels(items_relations_hash, lang='')

      paginate(items_relations_hash.keys, @items_limit).each do |page_items|

        items_hash = {} 
        label_stmts = []
        relations_set = Set.new
        subject_count = 0
        vars_hash = {}
        relations_hash = {}

        page_items.each do |item|
          item_uri = Xplain::Namespace.expand_uri item.id
          label_relations = items_relations_hash[item]
          label_relations.each do |r|
            r_uri = Xplain::Namespace.expand_uri(r)
            if !relations_hash.has_key? r_uri
              relations_hash[r_uri] = []
            end
            relations_hash[r_uri] << item
          end
          items_hash[item_uri] = item
        end

        statements = relations_hash.entries.map do |rel, items|
          subject_count += 1
          subject_var = "?s#{subject_count}"
          object_var = "?o#{subject_count}"
          values_clause = items.map{|i| "<" + Xplain::Namespace.expand_uri(i.id) + ">"}.join(" ")
          values_stmt = "VALUES #{subject_var} {#{values_clause}}."
          
          stmt = "OPTIONAL{#{subject_var} <#{Xplain::Namespace.expand_uri(rel)}> #{object_var}. #{values_stmt}"
          if !lang.to_s.empty?
            stmt << " FILTER(lang(#{object_var})='#{lang}')"
          end
          stmt << "}"

          stmt
        end
        
        
        if statements.empty?
          return
        end
        
        query = "SELECT * WHERE {#{statements.join(" ")}}"
        puts "-------TEXT QUERY---------"
        puts query
        
        @graph.query(query).each_solution do |sol|
          item = nil
          sol.each do |b| 
            
            
            if b[0].to_s.include? "s"
              uri = sol[b[0].to_sym].to_s
              item = items_hash[uri]
              
            elsif b[0].to_s.include? "o"
              
              item.text = sol[b[0].to_sym].to_s
            end

            
          end
          
        end
        
        
      end

    end


    def set_items_labels_old(items_relations_hash)
      
      paginate(items_relations_hash.keys, @items_limit).each do |page_items|

        items_hash = {} 
        label_stmts = []
        relations_set = Set.new
        triple_count = 0
        vars_hash = {}

        page_items.each do |item|
          label_relations = items_relations_hash[item]

          item_id_expanded = Xplain::Namespace.expand_uri(item.id)
          
          if !items_hash.has_key? item.id
            vars_hash[item_id_expanded] = []
            
          end
          items_hash[item_id_expanded] = item
          label_relations.each do |relation|
            label_var = "?o#{triple_count += 1}"
            vars_hash[item_id_expanded] << label_var
            
            label_stmts << "<#{item_id_expanded}> <#{Xplain::Namespace.expand_uri(relation)}> #{label_var}"
          end

        end
        
        if label_stmts.empty?
          return
        end

        construct_clause = label_stmts.join(".\n")
        where_clause = label_stmts.map{|l| "OPTIONAL{#{l}}"}.join(".\n")
        
        
        query = "CONSTRUCT {#{construct_clause}} WHERE{#{where_clause}}"
        puts "-------TEXT QUERY---------"
        puts query
        @graph.query(query).each_statement do |stmt|
          
          items_hash[stmt[0].to_s].text = stmt[2].to_s
        end
        
      end
    end
    
    
    def insert_ibge
      
      insert_stmt = File.open("insert.txt", "r").readlines[0]
      execute_update(insert_stmt, content_type: content_type)
    end
    
    def remove_document_contexts
      offset = 0
      count = 0
      while count < 100
        query = "select ?s ?p ?p2 ?o ?o2 where{?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://purl.org/spar/pro/RoleInTime>. ?s <http://purl.org/spar/pro/withRole> <http://purl.org/spar/pro/publisher>.  ?s ?p ?o. ?o2 ?p2 ?s} limit 1000 offset #{offset}"
        
        rs = @graph.query(query)
        delete_data = "delete data{"
        rs.each_solution do |s|
          delete_data << "<#{s[:s].to_s}> <#{s[:p].to_s}> "
          if s[:o].literal?
            delete_data << "\"#{s[:o].to_s}\""
          else
            delete_data << "<#{s[:o].to_s}>"
          end
          
          delete_data << " . <#{s[:o2].to_s}> <#{s[:p2].to_s}> <#{s[:s].to_s}>"
          delete_data << ". "
        end
        delete_data << "}"
        ur = execute_update(delete_data, content_type: content_type)
        
        puts "Offset: #{offset}"
        puts "Delete results: #{ur.to_s}"
        offset += 1000 - 1
        count += 1
      end
      
    end
    
    
    def execute_update(query, options = {})
      @graph.update(query, options)
    end
    
    def dataset_filter(input_items = [], filter_expr)
      interpreter = SPARQLFilterInterpreter.new()
      results = Set.new
      parsed_query = interpreter.parse(filter_expr)
      paginate(input_items, @items_limit).each do |page_items|
        query = "SELECT ?s ?ls "
        if !@named_graph.to_s.empty?
           query << "FROM <#{@named_graph}>"
        end
        query << " where{"
        query << values_clause("?s", page_items)
        query << parsed_query + "."
        query << mount_label_clause("?s", page_items) + "}"
        results += get_filter_results(query)
      end
      items_h = input_items.map{|i| [i.id, i]}.to_h
      results.map{|i| items_h[i.id]}
    end
    
    def validate_filters(filter_expr)
      interpreter = SPARQLFilterInterpreter.new()
      invalid_filters = interpreter.validate_filters(filter_expr)
      return invalid_filters
    end
    
    def can_filter?(filter_expr)
      interpreter = SPARQLFilterInterpreter.new()
      interpreter.can_filter? filter_expr
    end
    
    def can_aggregate?(items, aggregation_function)
      true
    end
    
    def paginate(items_list, page_size)
      
      return [items_list] if !(page_size.to_i > 0)
      
      offset = 0
      pages = []
      while offset < items_list.size
        pages << items_list[offset..(offset+page_size)]
        offset += page_size
      end
      pages
    end
    
    def to_ruby
      DSLParser.new.parse_data_server(self).gsub("\"", '\"')
    end

    def text
      @params['title'] || @params['graph']
    end

    def save()
      delete_stmt ="DELETE WHERE{<#{@params[:graph]}> ?p ?o.}"
      

      if !Xplain::exploration_repository.execute_update(delete_stmt, content_type: content_type)
        puts delete_stmt
        raise Exception.new("Error on deleting server with url: #{@params[:graph]}")
      end


      insert_stmt = <<-eos
        INSERT DATA{
          <#{@params[:graph]}> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Server>.
          <#{@params[:graph]}> <#{@xplain_ns.uri}class> \"#{self.class.name}\".
          <#{@params[:graph]}> <#{@dcterms.uri}title> \"#{@text}\".
          <#{@params[:graph]}> <#{@xplain_ns.uri}graph> \"#{@params[:named_graph].to_s}\".
          <#{@params[:graph]}> <#{@xplain_ns.uri}http_method> \"#{@params[:method]}\".
          <#{@params[:graph]}> <#{@xplain_ns.uri}limit_per_query> #{@params[:results_limit]}.
          <#{@params[:graph]}> <#{@xplain_ns.uri}timeout> #{@params[:read_timeout]}.
          <#{@params[:graph]}> <#{@xplain_ns.uri}ignore_literal_centric_queries> \"#{@params[:ignore_literal_queries]}\".
          <#{@params[:graph]}> <#{@xplain_ns.uri}items_limit_per_query> #{@params[:items_limit]}.
          <#{@params[:graph]}> <#{@xplain_ns.uri}ruby_code> \"#{to_ruby}\".
      eos

      if self.lookup_service
        insert_stmt << "<#{@params[:graph]}> <#{@xplain_ns.uri}lookup_service> \"#{self.lookup_service.class.to_s}\"."
      end

      insert_stmt << "}"
      
      if !Xplain::exploration_repository.execute_update(insert_stmt, content_type: content_type)
        puts insert_stmt
        raise Exception.new("Error on saving server with url: #{@params[:graph]}")
        
      end
    end
    
    def load(id)
      
      load_all.select{|s| s.url == id}.first
    end

    def load_all()
      @rdf_ns = Xplain::Namespace.new("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
      @dcterms = Xplain::Namespace.new("dcterms", "http://purl.org/dc/terms/")
      @xplain_ns = Xplain::Namespace.new("xplain", "http://tecweb.inf.puc-rio.br/xplain/")
      server_list = []
      query = <<-eos
        SELECT * WHERE{
          ?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Server>.
          OPTIONAL{?s <#{@dcterms.uri}title> ?txt}.
          OPTIONAL{?s <#{@xplain_ns.uri}graph> ?ngraph}.
          OPTIONAL{?s <#{@xplain_ns.uri}class> ?class}.
          OPTIONAL{?s <#{@xplain_ns.uri}http_method> ?m}.
          OPTIONAL{?s <#{@xplain_ns.uri}limit_per_query> ?lim}.
          OPTIONAL{?s <#{@xplain_ns.uri}timeout> ?timeout}.
          OPTIONAL{?s <#{@xplain_ns.uri}ignore_literal_centric_queries> ?ig_lit}.
          OPTIONAL{?s <#{@xplain_ns.uri}items_limit_per_query> ?ilim}.
          OPTIONAL{?s <#{@xplain_ns.uri}lookup_service> ?lservice}.
        }
      eos
      puts "-----------SERVERS LOAD ALL QUERY-----------"
      puts query
      

      Xplain::exploration_repository.graph.query(query).each do |solution|
        params = {}
        params[:graph] = solution[:s].to_s
        params[:named_graph] = solution[:ngraph].to_s
        params[:results_limit] = solution[:lim].to_s.to_i
        params[:read_timeout] = solution[:timeout].to_s.to_i
        params[:ignore_literal_queries] = eval(solution[:ig_lit].to_s)
        params[:items_limit] = solution[:ilim].to_s.to_i
        params[:text] = solution[:txt].to_s
        params[:method] = solution[:m].to_s
        params[:lookup_service] = solution[:lservice].to_s
        server_list << eval(solution[:class].to_s).new(params)
      end
      
      server_list

    end
  end

end
