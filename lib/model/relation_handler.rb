class RelationHandler
  def initialize(item)
    @item = Xplain::Node.new item: item
  end
  
  def handle_call(m, *args, &block)
    relation_id = ""
    relation_ns = ""
    relation_name = m.to_s
    
    if m.to_s.include?('__')
      relation_ns = m.to_s.split('__').first
      relation_name = m.to_s.split('__').last
      relation_id = relation_ns + ':'
    end
    relation_id += relation_name
    
    inverse = false
    data_server = @item.item.server
    if !args.empty?
      args_index = -1
      inverse = (args[args_index+=1] == :inverse)
      
      #TODO refactor to correctly test whether the arg is a DataServer instance
      data_server = args[args_index] if args[args_index+=1].class.name.include? "DataServer" 
    end
    # data_server ||= Xplain.default_server
    #TODO the relation can be queried in many data servers, correct the server parameter to cover this case 
    
    relation = Xplain::SchemaRelation.new(server: data_server, id: relation_id, inverse: inverse)
    
    relation.restricted_image([@item]).sort_asc
  end
end