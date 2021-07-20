module Xplain::RDF
  module SessionMapper
    
    def session_add_result_set(session, result_set)
      uri = Xplain::Namespace.expand_uri(session.id)
      insert_stmt = "INSERT DATA{
      <#{uri}> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Session>.
      <#{uri}> <#{@dcterms.uri}title> \"#{session.title}\". 
      <#{uri}> <#{@xplain_ns.uri}contains_set> <#{result_set.id}>.
      <#{uri}> <#{@xplain_ns.uri}server> <#{session.server.id}>.}"
      
      execute_update(insert_stmt, content_type: content_type)
    end
    
    def session_remove_result_set(session, result_set)
      uri = Xplain::Namespace.expand_uri(session.id)
      insert_stmt = "DELETE DATA{
      <#{uri}> <#{@xplain_ns.uri}contains_set> <#{result_set.id}>}"
      execute_update(insert_stmt, content_type: content_type)
    end
    
    def session_save(session)
      uri = Xplain::Namespace.expand_uri(session.id)
      delete_stmt = "DELETE WHERE{ <#{uri}> <#{@dcterms.uri}title> ?t. <#{uri}> <#{@xplain_ns.uri}server> ?o. <#{uri}> <#{@xplain_ns.uri}has_view_profile> ?v}"
      execute_update(delete_stmt, content_type: content_type)
      
      insert_stmt = "INSERT DATA{
      <#{uri}> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Session>.
      <#{uri}> <#{@dcterms.uri}title> \"#{session.title}\".
      <#{uri}> <#{@xplain_ns.uri}server> <#{session.server.id}>."
      
      if session.view_profile
        session.view_profile.save
        insert_stmt << "<#{uri}> <#{@xplain_ns.uri}has_view_profile> <#{Xplain::Namespace.expand_uri(session.view_profile.id)}>."
      end

      insert_stmt << "}"
      
      execute_update(insert_stmt, content_type: content_type)
    end
    

    def session_load(id, where_append = "")
      session_query = "SELECT ?title ?server ?profile WHERE{<#{@xplain_ns.uri + id}> <#{@dcterms.uri}title> ?title. OPTIONAL{<#{@xplain_ns.uri + id}> <#{@xplain_ns.uri}server> ?server}. OPTIONAL{<#{@xplain_ns.uri + id}> <#{@xplain_ns.uri}has_view_profile> ?profile}. #{where_append}}"
      session = nil
      @graph.query(session_query).each do |solution|
        
        title = solution[:title].to_s
        session = Xplain::Session.new(id: id, title: title)
        if solution[:server]
          #TODO implement a load method
          server = Xplain::DataServer.load(solution[:server].to_s)
          session.server = server
        end
        

        if solution[:profile]
          view_profile = Xplain::Visualization::Profile.load(solution[:profile].to_s)
          session.view_profile = view_profile
        end
        
      end
      
      
      self.result_set_find_by_session(session, exploration_only: true)
       
      session
    end
    
    def session_find_by_title(title)
      session_find(title: title)
    end

    def session_find(params)
      id = params[:id]
      title = params[:title]
      sessions_found = {}
      
      
      session_query = "SELECT ?s ?title ?server ?profile WHERE{?s a <#{@xplain_ns.uri}Session>. ?s <#{@dcterms.uri}title> ?title. OPTIONAL{?s <#{@xplain_ns.uri}server> ?server}. OPTIONAL{?s <#{@xplain_ns.uri}has_view_profile> ?profile}."
      
      if id
        session_query << "VALUES ?s {<#{@xplain_ns.uri + id}>}."
      end

      if title
        session_query << "FILTER(regex(str(?title), \".*#{title}.*\"))."
      end


      session_query << "}"
      

      @graph.query(session_query).each do |solution|

        title = solution[:title].to_s
        id = Xplain::Namespace.colapse_uri(solution[:s].to_s)
        
        if !sessions_found.has_key?(solution[:s].to_s)
          sessions_found[solution[:s].to_s] = Xplain::Session.new(id: id, title: title)
        end

        session = sessions_found[solution[:s].to_s]
        
        if solution[:server]
          #TODO implement a load method
          server = Xplain::DataServer.load(solution[:server].to_s)
          session.server = server
          
        end

        if solution[:profile]
          view_profile = Xplain::Visualization::Profile.load(solution[:profile].to_s)
          session.view_profile = view_profile
        end
        
      end
      
      sessions_found.values
    end
    
    def session_list_titles
      session_query = "SELECT ?t WHERE{?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Session>. ?s <#{@dcterms.uri}title> ?t}"
      titles = []
      @graph.query(session_query).each do |solution|
        titles << solution[:t].to_s
      end
      titles
    end
    
    def session_delete(session)
      uri = Xplain::Namespace.expand_uri session.id
      delete_stmt = "DELETE WHERE{<#{uri}> ?p ?o}"
      execute_update(delete_stmt, content_type: content_type)
    end

    def namespace_find_all
      query = <<-eos 
        SELECT * WHERE {?s  <#{@xplain_ns.uri}has_prefix> ?prefix. 
        ?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Namespace>.}
      eos
      ns_list = []
      
      @graph.query(query).each do |solution|
        ns_list << Xplain::Namespace.new(solution[:prefix].to_s, solution[:s].to_s.gsub("xpln_ns", ""))
      end
      
      ns_list
    end
    
    def namespace_delete_all()
      delete_stmt = "DELETE WHERE{?s ?p ?o. ?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Namespace>}"
      execute_update(delete_stmt, content_type: content_type)
    end

    def namespace_save(namespace)
      delete_stmt = "DELETE WHERE{<#{namespace.uri}xpln_ns> ?p ?o}"
      execute_update(delete_stmt, content_type: content_type)
      insert = <<-eos
        INSERT DATA {
          <#{namespace.uri}xpln_ns> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Namespace>.
          <#{namespace.uri}xpln_ns> <#{@xplain_ns.uri}has_prefix> \"#{namespace.prefix}\".
        }
      eos
      result = execute_update(insert, content_type: content_type)
      return !result.nil?
    end
  end
end