require 'forwardable'

require 'linkeddata'
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

graph_url = "http://localhost:3002/blazegraph/namespace/kb/sparql"

# setting the blazegraph server as the default data server for the exploration tasks
Xplain.set_default_server class: BlazegraphDataServer, graph: graph_url, method: 'post', results_limit: 10000, items_limit: 0, read_timeout: 3000

adapter = Xplain.default_server
adapter.insert_ibge
