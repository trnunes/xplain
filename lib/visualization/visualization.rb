module Xplain
  module Visualization
    class Profile
      include Xplain::ProfileWritable
      extend Xplain::ProfileReadable
      #TODO implement profiles creation, update, load and list
      
      attr_accessor :id, :name, :labels_by_type_dict, :item_text_dict, :inverse_relation_text_dict

      def initialize(params)
        @id = params[:id]
        
        
        if !(@id)
          raise "Cannot create a profile with empty name!"
        end

        if !(Xplain::Namespace.expand_uri(@id).include?("http://tecweb.inf.puc-rio.br/xplain/"))
          @id = "http://tecweb.inf.puc-rio.br/xplain/#{@id.gsub(" ", "_")}"
        end
        @name = params[:name]

        @labels_by_type_dict = params[:labels_by_type_dict] || {}
        @image_label_relations_hash = params[:image_label_relations_hash] || {}
        @domain_label_relations_hash = params[:domain_label_relations_hash] || {}
        @item_text_dict = params[:item_text_dict] || {}
        @inverse_relation_text_dict = params[:inverse_relation_text_dict] || {}
        
      end
      
      def labels_by_type_dict=(dict)
        @labels_by_type_dict = {}
        dict.entries.each do |type, relations|
          @labels_by_type_dict[Xplain::Namespace.expand_uri(type)] = relations.map{|r| Xplain::Namespace.expand_uri(r)}
        end
      end
      
      def relation_text_dict=(dict)
        @item_text_dict = {}
        dict.entries.each do |relation, text|
          @item_text_dict[Xplain::Namespace.expand_uri(relation)] = text
        end
      end

      def inverse_relation_text_dict=(dict)
        @inverse_relation_text_dict = {}
        dict.entries.each do |relation, text|
          @inverse_relation_text_dict[Xplain::Namespace.expand_uri(relation)] = text
        end
      end

      def set_view_properties(nodes, lang='')
        
        servers_hash =  {}
        item_nodes = nodes.select{|n| !n.item.is_a?(Xplain::Literal)}

        items_hash = item_nodes.map{|n| [Xplain::Namespace.expand_uri(n.item.id), n.item]}.to_h

        items_hash.values.each do |item|
          if item.is_a?(Xplain::Type) || item.types.empty? || !item.server
            next
          end
          
          if !servers_hash.has_key?(item.server)
            servers_hash[item.server] = {}
          end

          relations = item.types.map{|t| self.labels_by_type_dict[Xplain::Namespace.expand_uri(t.id)]}.flatten.uniq.compact
          
          servers_hash[item.server][item] = relations
        end

        servers_hash.entries.each do |server, items_relations_hash|

          server.set_items_labels(items_relations_hash, lang)
        end

        
        nodes.each do |node|
          
          if node.item.is_a?(Xplain::Item) || node.item.is_a?(Xplain::Relation)
            text = @item_text_dict[Xplain::Namespace.expand_uri(node.item.id)]
            if text
              node.item.text = text
            end
          end
          if node.item.is_a?(Xplain::Relation) && node.item.inverse?
            text = @inverse_relation_text_dict[Xplain::Namespace.expand_uri(node.item.id)]
            if text
              node.item.text = text
            end
          end

          if node.item.respond_to? :types
            node.item.types.each do |t|
              text = @item_text_dict[Xplain::Namespace.expand_uri(t.id)]
              if text
                t.text = text
              end
            end
          end
        end
        
        

      end
      
      def inverse_relation_text_for(relation_id, text)
        @inverse_relation_text_dict[Xplain::Namespace.expand_uri(relation_id)] = text
      end
      
      def inverse_relation_text(relation_id)
        @inverse_relation_text_dict[Xplain::Namespace.expand_uri(relation_id)]
      end
      
      def text_for(item_id, text)
        @item_text_dict[Xplain::Namespace.expand_uri(item_id)] = text
      end
      
      def label_relations_for(type)
        
        @labels_by_type_dict[Xplain::Namespace.expand_uri(type)] || []
      end
    
      def label_for_type(type, *relations)
        if !@labels_by_type_dict.has_key?(Xplain::Namespace.expand_uri(type))
          @labels_by_type_dict[Xplain::Namespace.expand_uri(type)] = []
        end
        relations.each do |r|
          @labels_by_type_dict[Xplain::Namespace.expand_uri(type)] << Xplain::Namespace.expand_uri(r)
        end
      end
      
      def label_for_image(relation, label_relation)
        @image_label_relations_hash[Xplain::Namespace.expand_uri(relation.id)] = [Xplain::Namespace.expand_uri(label_relation)]
      end
      
      def label_for_domain(relation, label_relation)
        @domain_label_relations_hash[Xplain::Namespace.expand_uri(relation.id)] = [Xplain::Namespace.expand_uri(label_relation)]
      end
      
      def label_relations
        @labels_by_type_dict.values.flatten
      end
      
      def domain_label_relations(relation)
        @domain_label_relations_hash[Xplain::Namespace.expand_uri(relation.id)] || []
      end
      
      def image_label_relations(relation)
  
        @image_label_relations_hash[Xplain::Namespace.expand_uri(relation.id)] || []
      end
      
      def types
        @labels_by_type_dict.keys
      end

      def to_json
        
        json = "{\"id\":\"#{@id}\","
        json << "\"name\":\"#{@name}\","
        json << "\"labels_by_type_dict\":{"
        
        labels_by_type_json = labels_by_type_dict.entries.map do |type, relations|
          type_str = Xplain::Namespace.colapse_uri type
          relations_str = relations.map{|r| "\"#{Xplain::Namespace.colapse_uri(r)}\""}.join(",")
          "\"#{type_str}\": [#{relations_str}]"
        end.join(",")

        json << labels_by_type_json
        json << "},"
        
        json << "\"item_text_dict\": {"
        item_text_dict_json = item_text_dict.entries.map do |item_id, text|
          "\"#{Xplain::Namespace.colapse_uri(item_id)}\":\"#{text}\""
        end.join(",")
        
        json << item_text_dict_json
        json << "},"

        json << "\"inverse_relation_text_dict\":{"
        inverse_text_json = inverse_relation_text_dict.entries.map do |item_id, text|
          "\"#{Xplain::Namespace.colapse_uri(item_id)}\":\"#{text}\""
        end.join(",")
        json << inverse_text_json
        json << "}"

        json << "}"
      end

    end
    @@current_profile = Profile.new(id: 'default')
    
    def self.current_profile
      @@current_profile    
    end
    
    def self.current_profile=(profile)
      @@current_profile = profile
    end
  end
  

end