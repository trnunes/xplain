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
    DEFAULT_SET_VIEW = 'tree'
    
    #Change this to point to other endpoints    
    Rails.application.config.use_blazegraph_index = true
    graph_url = "http://opencitations.net/sparql"
    Explorable.use_cache(true)
    server = RDFDataServer.new(graph_url, method: 'get', results_limit: 10000, items_limit: 100, use_select: false)
    
    #TODO fix the need of a default set as starting point
    s = Xset.new('default_set', '') 
    s.server = server
    s.save
    
    # Config the repository of session information
    # Persistable.set_session_repository server

    #Namespaces
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
    Xpair::Namespace.new("dbpedia", "http://dbpedia.org/ontology/")
    
    #Visualization properties config
    module Xpair::Visualization
      label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "rdfs:label"
      label_for_type "http://purl.org/spar/fabio/Expression", "dcterms:title"
      label_for_type "http://purl.org/spar/fabio/JournalArticle", "dcterms:title"
      label_for_type "foaf:Agent", "foaf:name", "foaf:givenName"
      label_for_type "http://purl.org/spar/biro/BibliographicReference", "http://purl.org/spar/c4o/hasContent"
      label_for_type "http://purl.org/spar/fabio/Book", "dcterms:title"

      label_for_type "http://purl.org/spar/fabio/BookSeries", "dcterms:title"
      label_for_type "http://purl.org/spar/fabio/ProceedingsPaper", "dcterms:title"
    end
  end
end
