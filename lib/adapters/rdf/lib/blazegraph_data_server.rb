class BlazegraphDataServer < Xplain::RDF::DataServer
  def match_all(keyword_pattern, restriction_nodes = [], offset = 0, limit = 0)
    blaze_graph_search(keyword_pattern, restriction_nodes, offset, limit)
  end
  
  def blaze_graph_search(keyword_pattern, restriction_nodes = [], offset = 0, limit = 0)
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
    
    query = "select * where {#{values_clause("?s", restriction_nodes.map{|n|n.item})} ?o <http://www.bigdata.com/rdf/search#search> \" #{keyword_pattern.join(" ")}\". ?o <http://www.bigdata.com/rdf/search#matchAllTerms> \"true\" . ?s ?p ?o . #{label_clause}}"


    execute(query,{content_type: content_type, offset: offset, limit: limit}).each do |s|
      item = Xplain::Entity.create(Xplain::Namespace.colapse_uri(s[:s].to_s))
      i = 0
      for i in 0..label_relations.size-1 do
        break if !s["ls#{i}".to_sym].nil?
      end 
      item.text = s["ls#{i}".to_sym].to_s
      item.text_relation = label_relations[i] if i >= 0
      item.add_server(@server)
      items << item
    end
    items.uniq.sort{|i1, i2| i1.text <=> i2.text}
  end
end