module Xplain::RDF
    module ViewMapper
        def view_add_profile(profile)
            
            uri = profile.id
            delete_stmt = "DELETE WHERE {<#{uri}> ?p ?o}"
            execute_update(delete_stmt, content_type: content_type)

            insert_stmt = "INSERT DATA { 
                <#{uri}> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}ViewProfile>.                
            "
            text = profile.name
            if text.nil? || text.empty?
                text = uri.split("/").last.gsub("_", " ")
            end

            insert_stmt << "<#{uri}> <#{@dcterms.uri}title> \"#{text}\"."

            triples = []

            profile.labels_by_type_dict.keys.each do |type|
                label_relations = profile.labels_by_type_dict[type]

                profile_str_for_type = Xplain::Namespace.expand_uri(type) + "<=>" + label_relations.map{|r| Xplain::Namespace.expand_uri(r)}.join("<=>")

                triples << "<#{uri}> <#{@xplain_ns.uri}has_view_type> \"#{profile_str_for_type}\""
            end
            
            profile.item_text_dict.entries.each do |relation, text|
                triples << "<#{uri}> <#{@xplain_ns.uri}label_for> \"#{Xplain::Namespace.expand_uri(relation)}<=>#{text}\""
            end

            profile.inverse_relation_text_dict.entries.each do |relation, text|
                triples << "<#{uri}> <#{@xplain_ns.uri}inverse_label_for> \"#{Xplain::Namespace.expand_uri(relation)}<=>#{text}\""
            end
            
            insert_stmt << triples.join(" . ")
            insert_stmt << "}"


            execute_update(insert_stmt, content_type: content_type)
            

        end

        

        def view_remove_profile(profile)

        end

        def load_profile(id)
            find_profiles(id: id).first
        
        end



        def load_profile_by_name(profile_name)
            find_profiles(name: profile_name)
        end

        def find_profiles(params = {})
                  

            profiles_dict = {}

            profile_query = "SELECT ?s ?p ?o WHERE {?s ?p ?o. ?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}ViewProfile>"
            
            if params[:id]
                profile_query << "VALUES ?s {<#{Xplain::Namespace.expand_uri(params[:id])}>}."
                
            end

            if params[:name]
                id = params[:name].gsub(" ", "_" )
                profile_query << "VALUES ?s {<#{@xplain_ns.uri + id}>}."
            end
            profile_query << "}"
            
            @graph.query(profile_query).each do |solution|
                obj = ""
                profile_uri = Xplain::Namespace.colapse_uri solution[:s].to_s
                if !profiles_dict.has_key? profile_uri
                    profiles_dict[profile_uri] = {
                        id: profile_uri,
                        name: "",
                        labels_by_type_dict: {},
                        item_text_dict: {},
                        inverse_relation_text_dict: {}
                    
                    }
                end
                

                if solution[:o].to_s.include? "<=>"
                    
                    obj_array = solution[:o].to_s.split("<=>")
                    hash_key = obj_array.first
                    hash_values = obj_array[1, obj_array.size]
                    
                end

                if solution[:p].to_s == "#{@dcterms.uri}title"
                    profiles_dict[profile_uri][:name] = solution[:o].to_s
                
                elsif solution[:p].to_s == "#{@xplain_ns.uri}has_view_type"
                    profiles_dict[profile_uri][:labels_by_type_dict][hash_key] = hash_values
                elsif solution[:p].to_s == "#{@xplain_ns.uri}label_for"
                    profiles_dict[profile_uri][:item_text_dict][hash_key] = hash_values.first
                elsif solution[:p].to_s == "#{@xplain_ns.uri}inverse_label_for"
                    profiles_dict[profile_uri][:inverse_relation_text_dict][hash_key] = hash_values.first
                end
            end
            
            profiles = profiles_dict.values.map{|profile_data| Xplain::Visualization::Profile.new(profile_data)}
            profiles
      
        end
    end
end