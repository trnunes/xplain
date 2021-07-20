require 'xplain'
require 'pry'

###
### Setting the namespaces for the opencitations dataset
###
Xplain::Namespace.new("uspat", "http://us.patents.aksw.org/")
Xplain::Namespace.new("fabio", "http://purl.org/spar/fabio/")
Xplain::Namespace.new("cito", "http://purl.org/spar/cito/")
Xplain::Namespace.new("c4o", "http://purl.org/spar/c4o/")
Xplain::Namespace.new("biro", "http://purl.org/spar/biro/")
Xplain::Namespace.new("spardatacite", "http://purl.org/spar/datacite/")
Xplain::Namespace.new("sparpro", "http://purl.org/spar/pro/")
Xplain::Namespace.new("prismstandard", "http://prismstandard.org/namespaces/basic/2.0/")
Xplain::Namespace.new("sparpro", "http://purl.org/spar/pro/")
Xplain::Namespace.new("frbr", "http://purl.org/vocab/frbr/core#")
Xplain::Namespace.new("w3iont", "https://w3id.org/oc/ontology/")

#Visualization properties config
module Xplain::Visualization
  label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "rdfs:label"
  label_for_type "http://purl.org/spar/fabio/Expression", "dcterms:title"
  label_for_type "http://purl.org/spar/fabio/JournalArticle", "dcterms:title"
  label_for_type "foaf:Agent", "foaf:name", "foaf:givenName"
  label_for_type "http://purl.org/spar/biro/BibliographicReference", "http://purl.org/spar/c4o/hasContent"
  label_for_type "http://purl.org/spar/fabio/Book", "dcterms:title"

  label_for_type "http://purl.org/spar/fabio/BookSeries", "dcterms:title"
  label_for_type "http://purl.org/spar/fabio/ProceedingsPaper", "dcterms:title"
end

###
### Setting up the local blazegraph server containing the open citations 
### dataset running at localhost, port 3001.
###

graph_url = "http://localhost:3001/blazegraph/namespace/kb/sparql"
Xplain.set_default_server class: BlazegraphDataServer, graph: graph_url

###
### Uncoment the following two lines to setup the remote opencitations endpoint
###
# graph_url = "http://opencitations.net/sparql"
# Xplain.set_default_server class: BlazegraphDataServer, graph: graph_url, method: "get",  results_limit: 10000, items_limit: 100 

# instantiating the metarelation "has_type" that maps instances to their respective types 
has_type_relation = Xplain::SchemaRelation.new(id: "has_type")

# retrieving the image of the "has_type" metarelation which is the set of all types of the open citations dataset
all_types = has_type_relation.image

book_types = all_types.select{|type| type.item.id == "fabio:BookSeries"}.first

#Selecting a node from the book_types result set
book_series_type = all_types.nodes_select(["fabio:BookSeries"]).execute() 

#pivoting to the instances of the book series type
book_series = book_series_type.pivot do
  relation inverse "rdf:type"
end.execute()

puts "RESULTS"
puts "----------BOOK SERIES----------------"
book_series.each{|book_node| puts book_node.item.text}; puts
puts

# Pivoting to the relations of the book series
book_series_relations = book_series.pivot{relation "relations"}.execute()

puts "------------BOOK SERIES RELATIONS----------------"
book_series_relations.each{|relation| puts relation.item.text}; puts
