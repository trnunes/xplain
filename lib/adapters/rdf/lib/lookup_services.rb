require 'nokogiri'
require 'typhoeus'

module Xplain    
    class DbpediaLookup

        def initialize(server=nil)
            @server = server
        end

        def lookup(keyword_phrase, restriction_nodes = [], offset = 0, limit = 0)
            keyword_phrase = keyword_phrase.join(" ") if keyword_phrase.is_a? Array
            keyword_phrase = keyword_phrase.gsub("\s", "%20")
            url = "https://lookup.dbpedia.org/api/search.asmx/KeywordSearch?&QueryString=#{keyword_phrase}&MaxHits=1000"
            
            
            response = Typhoeus::Request.get(url)
            
            if response.code != 200
                raise "There was a problem while contacting server!"
            end
            
            parse_results(response)
        end

        def parse_results(response)
            
            xml = Nokogiri::XML(response.body)
            result_items = []
            nodes = xml.xpath("//ArrayOfResults")
            nodes.children.each do |n| 
                label = n.xpath('Label').text
                
                desc = n.xpath('Description').text
                uri = n.xpath('URI').text

                item = Xplain::Entity.create(Xplain::Namespace.colapse_uri(uri), label, @server)
                result_items << item
            end
            result_items
        end
    end

    class BlazegraphLookup
        def initialize(server)
            @server = server
        end

        def lookup(keyword_pattern, restriction_nodes = [], offset = 0, limit = 0)
            filters = []
            unions = []
            items = []
            
            label_relations = Xplain::Visualization.current_profile.label_relations_for("rdfs:Resource")
            label_clause = ""
            for i in 0..label_relations.size-1 do
              var = "?ls" << i.to_s
              l_relation = label_relations[i]
              label_clause << "OPTIONAL{?s <#{l_relation}> #{var}}."
            end
            values_clause = ""
            if !restriction_nodes.empty?

                values_uris = restriction_nodes.map{|n|"<" + n.item.id + ">"}.join(" ")
                values_clause = "VALUES ?s{#{values_uris}}."
            end
            
            query = "select * where {#{values_clause} ?o <http://www.bigdata.com/rdf/search#search> \" #{keyword_pattern.join(" ")}\". ?o <http://www.bigdata.com/rdf/search#matchAllTerms> \"true\" . ?s ?p ?o . OPTIONAL{?s a ?t}. #{label_clause}}"
        
            items_hash = {}
            @server.execute(query,{content_type: @server.content_type, offset: offset, limit: limit}).each do |solution|
                subject_uri = solution[:s].to_s

                if !items_hash.has_key? subject_uri
                    items_hash[subject_uri] = Xplain::Entity.create(Xplain::Namespace.colapse_uri(subject_uri))
                end
                
                item = items_hash[subject_uri]
                i = 0
                for i in 0..label_relations.size-1 do
                  break if !solution["ls#{i}".to_sym].nil?
                end 
                item.text = solution["ls#{i}".to_sym].to_s
                item.text_relation = label_relations[i] if i >= 0
                item.add_server(@server)
                
                if solution[:t]
                    item.types << Xplain::Type.create(Xplain::Namespace.colapse_uri(solution[:t].to_s))
                end
            end
            
            items_hash.values.uniq.sort{|i1, i2| i1.text <=> i2.text} 

        end

        

    end
end