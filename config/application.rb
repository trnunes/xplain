require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Wxpair
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

    # Do not swallow errors in after_commit/after_rollback callbacks.

    
    papers_graph = RDF::Graph.new do |graph|
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p2")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:label"), RDF::URI("_:paper1")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p4")]
      graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p2")]
      graph << [RDF::URI("_:p6"),  RDF::URI("_:label"), RDF::URI("_:p6")]
      graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p7"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:p7"),  RDF::URI("_:label"), RDF::URI("_:p7")]
      graph << [RDF::URI("_:p7"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p8"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p8"),  RDF::URI("_:label"), RDF::URI("_:p8")]
      graph << [RDF::URI("_:p8"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:p9"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p9"),  RDF::URI("_:label"), RDF::URI("_:p9")]
      graph << [RDF::URI("_:p10"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p10"),  RDF::URI("_:label"), RDF::URI("_:p10")]
      
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:submittedTo"), RDF::URI("_:journal1")]
      
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:author"),RDF::URI("_:a1") ]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:author"),RDF::URI("_:a2") ]
      graph << [RDF::URI("_:p2"),  RDF::URI("_:author"), RDF::URI("_:a1")]
      graph << [RDF::URI("_:p2"),  RDF::URI("_:label"), RDF::URI("lp2")]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:author"), RDF::URI("_:a2")]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:label"), RDF::URI("lp3")]
      graph << [RDF::URI("_:p5"),  RDF::URI("_:author"), RDF::URI("_:a1")]
      graph << [RDF::URI("_:p5"),  RDF::URI("_:author"), RDF::URI("_:a2")]
      graph << [RDF::URI("_:p5"),  RDF::URI("_:label"), RDF::URI("_:p5")]

      graph << [RDF::URI("_:p2"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal1")]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal2")]
      graph << [RDF::URI("_:p4"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal1")]
      
      graph << [RDF::URI("_:journal1"),  RDF::URI("_:releaseYear"),RDF::Literal.new(2005)]
      graph << [RDF::URI("_:journal2"),  RDF::URI("_:releaseYear"),RDF::Literal.new(2010)]
      
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k1")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k2")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k3")]
      
      graph << [RDF::URI("_:p2"),  RDF::URI("_:keywords"), RDF::URI("_:k3")]      
      graph << [RDF::URI("_:p3"),  RDF::URI("_:keywords"), RDF::URI("_:k2")]
      graph << [RDF::URI("_:p5"),  RDF::URI("_:keywords"), RDF::URI("_:k1")]
      
      graph << [RDF::URI("_:p2"),  RDF::URI("_:publicationYear"), 2000]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:publicationYear"), 1998]
      graph << [RDF::URI("_:p4"),  RDF::URI("_:publicationYear"), 2010]     
    end
    # papers_graph = RDF::Graph.load("./datasets/semanticlancet.ttl")
    # papers_graph = "http://192.168.0.15:3000/blazegraph/namespace/uspat/sparql"
    papers_graph = "http://localhost:3000/blazegraph/namespace/kb/sparql"

    # server = RDFDataServer.new(papers_graph, method: "get", results_limit: 5000, items_limit: 25, use_select: false)
    

    # papers_graph = "http://us.patents.aksw.org/sparql"

    Explorable.use_cache(true)
    server = RDFDataServer.new(papers_graph, results_limit: 10000, items_limit: 500, use_select: false)
    # server.label_property = RDF::RDFS.label.to_s
    s = Xset.new('default_set', '') 
    s.server = server
    
    s.save
    
    Persistable.set_session_repository server
    
    test_set = Xset.new('test_set', '')
    test_set.add_item Entity.new("_:paper1")
    test_set.add_item Entity.new("_:p2")
    test_set.add_item Entity.new("_:p3")
    test_set.add_item Entity.new("_:p4")
    test_set.add_item Entity.new("_:p5")
    test_set.add_item Entity.new("_:p6")
    test_set.add_item Entity.new("_:p7")
    test_set.add_item Entity.new("_:p8")
    test_set.add_item Entity.new("_:p9")
    test_set.add_item Entity.new("_:p10")
    test_set.server = server
    test_set.save
    # module Xpair::Visualization
    #
    #   label_for_type "uspat:ontology/Patent", "uspat:property/inventionTitle"
    #   label_for_image "uspat:property/international-classification", "uspat:property/class"
    #   label_for_image "uspat:property/applicant", "foaf:lastName"
    # end
    Xpair::Namespace.new("uspat", "http://us.patents.aksw.org/")
    Xpair::Namespace.new("fabio", "http://purl.org/spar/fabio/")
    Xpair::Namespace.new("cito", "http://purl.org/spar/cito/")
    Xpair::Namespace.new("c4o", "http://purl.org/spar/c4o/")
    Xpair::Namespace.new("biro", "http://purl.org/spar/biro/")
    Xpair::Namespace.new("spardatacite", "http://purl.org/spar/datacite/")
    Xpair::Namespace.new("sparpro", "http://purl.org/spar/pro/")
    Xpair::Namespace.new("prismstandard", "http://prismstandard.org/namespaces/basic/2.0/")
    Xpair::Namespace.new("sparpro", "http://purl.org/spar/pro/")
    Xpair::Namespace.new("frbr", "http://purl.org/vocab/frbr/core#")
    Xpair::Namespace.new("w3iont", "https://w3id.org/oc/ontology/")
    
    module Xpair::Visualization
      label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "http://purl.org/dc/terms/title"
      label_for_type "http://purl.org/spar/fabio/Expression", "http://purl.org/dc/terms/title"
      label_for_type "http://purl.org/spar/fabio/JournalArticle", "http://purl.org/dc/terms/title"
      label_for_type "foaf:Agent", "foaf:name", "foaf:givenName"
      label_for_type "http://purl.org/spar/biro/BibliographicReference", "http://purl.org/spar/c4o/hasContent"
      label_for_type "http://purl.org/spar/fabio/Book", "http://purl.org/dc/terms/title"
      label_for_type "http://purl.org/spar/fabio/ProceedingsPaper", "http://purl.org/dc/terms/title"
    end
    

  end
end
