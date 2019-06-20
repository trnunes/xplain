require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Wxplain
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.encoding = "utf-8"

    # Do not swallow errors in after_commit/after_rollback callbacks.
    DEFAULT_SET_VIEW = 'tree'
    
    #Change this to point to other endpoints
    session_graph_url = "http://localhost:3002/blazegraph/namespace/kb/sparql"    
    # graph_url = "http://opencitations.net/sparql"
     graph_url = "http://192.168.100.29:3001/blazegraph/namespace/kb/sparql"
    # graph_url = "http://localhost:3001/blazegraph/namespace/kb/sparql"

    # setting the blazegraph server as the default data server for the exploration tasks
    Xplain.set_default_server class: BlazegraphDataServer, graph: graph_url, method: 'post', results_limit: 10000, items_limit: 0, read_timeout: 3000, ignore_literal_queries: true
    
    Xplain.cache_results = true
    # setting the session information repository
    begin
      Xplain.set_exploration_repository class: BlazegraphDataServer, graph: session_graph_url, method: 'post', results_limit: 10000, items_limit: 0, read_timeout: 3000
    rescue Exception => e
    end  
    
    # Config the repository of session information
    # Persistable.set_session_repository server

    #Namespaces
    Xplain::Namespace.new("iff", "http://web.iff.edu.br/")
    
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
     #--------IBGE LABEL PROPERTIES---------------
     
     # current_profile.label_for_type "iff:uf", "rdf:label"
     # current_profile.label_for_type "iff:municipio", "rdf:label"
     # current_profile.label_for_type "iff:distrito", "rdf:label"
     # current_profile.label_for_type "iff:subdistrito", "rdf:label"
     # current_profile.label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "rdf:label"
     
     #--------OPENCITATIONS LABEL PROPERTIES---------------
     
     current_profile.label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "dcterms:title", "c4o:hasContent", "rdfs:label"
     current_profile.label_for_type "http://purl.org/spar/fabio/Expression", "dcterms:title"
     current_profile.label_for_type "http://purl.org/spar/fabio/JournalArticle", "dcterms:title"
     current_profile.label_for_type "foaf:Agent", "foaf:name", "foaf:givenName"
     current_profile.label_for_type "http://purl.org/spar/biro/BibliographicReference", "http://purl.org/spar/c4o/hasContent"
     current_profile.label_for_type "http://purl.org/spar/fabio/Book", "dcterms:title"

     current_profile.label_for_type "http://purl.org/spar/fabio/BookSeries", "dcterms:title"
     current_profile.label_for_type "http://purl.org/spar/fabio/ProceedingsPaper", "dcterms:title"
     current_profile.text_for "biro:references", "referências"
     current_profile.text_for "c4o:hasContent", "conteúdo"
     current_profile.text_for "cito:cites", "cita"
     current_profile.text_for "foaf:name", "nome"
     current_profile.text_for "foaf:givenName", "nome"
     current_profile.text_for "foaf:familyName", "sobrenome"
     current_profile.text_for "prismstandard:startingPage", "primeira página"
     current_profile.text_for "prismstandard:endingPage", "última página"
     current_profile.inverse_relation_text_for "cito:cites", "citado por"
     current_profile.text_for "frbr:part", "é parte"
     current_profile.text_for "frbr:partOf", "é parte de"
     current_profile.text_for "frbr:embodiment", "formato de publicação"
     current_profile.text_for "rdf:type", "categorias"
     current_profile.text_for "rdfs:label", "rótulos"
     current_profile.text_for "spardatacite:hasIdentifier", "identifcadores"
     current_profile.text_for "sparpro:isDocumentContextFor", "autores e/ou editores"
     current_profile.text_for "sparpro:isHeldBy", "autores"
     current_profile.text_for "sparpro:withRole", "papel"
     current_profile.text_for "dcterms:title", "título"
     current_profile.text_for "w3iont:hasNext", "próximo contexto"
     current_profile.text_for "fabio:hasPublicationYear", "ano de publicação"
     current_profile.text_for "fabio:Expression", "Documento Citado"
     current_profile.text_for "fabio:ExpressionCollection", "Conjunto de Citações"
     current_profile.text_for "fabio:JournalArticle", "Artigo de Revista"
     current_profile.text_for "fabio:JournalIssue", "Edição"
     current_profile.text_for "fabio:ProceedingsPaper", "Artigo"
     current_profile.text_for "fabio:AcademicProceedings", "Congresso"
     current_profile.text_for "fabio:ReportDocument", "Relatório Técnico"
     current_profile.text_for "fabio:Thesis", "Tese"
     current_profile.text_for "fabio:Book", "Livro"
     current_profile.text_for "fabio:BookSeries", "Coleção"
     current_profile.text_for "fabio:BookSet", "Caixa de Livros"
     current_profile.text_for "fabio:Series", "Série"
     current_profile.text_for "fabio:Manifestation", "Formato"
     current_profile.text_for "fabio:BookChapter", "Capítulo de Livro"
     current_profile.text_for "fabio:DataFile", "Arquivo de Dados"
     current_profile.text_for "fabio:Journal", "Revista"
     current_profile.text_for "fabio:JournalVolume", "Volume"
     
     current_profile.text_for "biro:BibliographicReference", "Referência Bibliográfica"
     
     
     current_profile.inverse_relation_text_for "w3iont:hasNext", "contexto anterior"
     
    end
    Xplain::SchemaRelation.inverse_suffix = "de"
  end
end
