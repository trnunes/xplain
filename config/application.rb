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

    # Do not swallow errors in after_commit/after_rollback callbacks.
    DEFAULT_SET_VIEW = 'tree'
    
    #Change this to point to other endpoints
    # graph_url = "http://localhost:3001/blazegraph/namespace/kb/sparql"
    graph_url = "http://opencitations.net/sparql"

    # setting the blazegraph server as the default data server for the exploration tasks
    Xplain.set_default_server class: BlazegraphDataServer, graph: graph_url, method: 'post', results_limit: 10000, items_limit: 0, read_timeout: 3000
    
    # setting the session information repository
    Xplain.set_exploration_repository class: MemoryRepository    
    
    # Config the repository of session information
    # Persistable.set_session_repository server

    #Namespaces
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
      label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "dcterms:title", "c4o:hasContent", "rdfs:label"
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
