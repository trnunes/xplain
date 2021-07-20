module Xplain
    
  class Namespace
    include NamespaceReadable
    include NamespaceWritable
    @@namespace_map = {}
    attr_accessor :prefix, :uri
    class << self

      def each(&block)
        @@namespace_map.values.sort{|ns1, ns2| -(ns1.prefix <=> ns2.prefix)}.each &block
      end

      def update(ns_map)
        delete_all        
        @@namespace_map = {}
        ns_map.each{|prefix, uri| Xplain::Namespace.new(prefix, uri).save}
      end
    
      def expand_uri(uri)
        
        prefix, suffix = uri.to_s.split(":", 2)
        expanded_uri = uri
        if @@namespace_map.has_key?(prefix)
          expanded_uri = @@namespace_map[prefix].uri + suffix
        end        
        expanded_uri.gsub(" ", "%20")
      end
    
      def colapse_uri(uri)
        return "" if uri.to_s.empty?
        @@namespace_map.values.each do |namespace|
          
          if(uri.include?(namespace.uri))
            prefix = namespace.prefix 
            if uri.split(namespace.uri).size > 1
              return prefix +":"+ uri.split(namespace.uri)[1]
            end
          end
        end
        return uri
      end
      #TODO move to NamespaceWritable
      def save_all
        @@namespace_map.values.each do |namespace|
          namespace.save
        end
      
      end

    end
  
    def initialize(prefix, uri)
      @prefix = prefix
      @uri = uri
      @@namespace_map[prefix] = self
    end
  end  
end