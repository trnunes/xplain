require 'json'

module OperationFactory
    def self.parse_item(item_hash)
        if item_hash["type"].downcase == "entity"
            return Xplain::Entity.new(id: item_hash["id"], title: item_hash["title"])
        elsif item_hash["type"].downcase == "relation"
        end
    end

    def self.parse(operationJson)


        rubyhash = JSON.parse(operationJson)
        operation_name = rubyhash.keys.first

        if operation_name == "pivot"
            
            inputs = rubyhash["pivot"]["inputs"]
            parsed_inputs = inputs.map do |input|
                if input.keys.first == "set"
                    input_nodes = input["set"].map do |item_hash|
                        Xplain::Node.new(item: parse_item(item_hash))
                    end                
                    Xplain::ResultSet.new(nodes: input_nodes)                
                elsif (false)
                elsif(false)
                end
            end

            relation = nil
            
            if (rubyhash[operation_name]["relation"])
                relation_id = rubyhash[operation_name]["relation"]
                
                parsed_rels = relation_id.split("->").map do |rel_id|
                    r_params = {}
                    if rel_id.include? "^"
                      rel_id.gsub!("^", "")
                      r_params[:inverse] = true
                    end
                    r_params[:id] = rel_id
                    Xplain::SchemaRelation.new(r_params)
                  end
    
                relation = Xplain::PathRelation.new(relations: parsed_rels)    
            end
            return Xplain::Pivot.new(inputs: parsed_inputs, relation: relation)            
        end

        return nil
    end
end
