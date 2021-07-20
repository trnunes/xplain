class DSLParser
  
  def parse_data_server(server)
    server.class.name + ".new#{parse_constructor_params(server.params)}"
  end
  
  def parse_operation(operation, parse_recursive=false)
    operation_code = ""
    inputs = operation.inputs
    
    parsed_inputs = []
    
    parsed_inputs = inputs.map do |input|
      if input.is_a? Xplain::Operation
        parse_operation(input)
      else
        parse_result_set(input)
      end
    end.compact
    #TODO implement the rule for more than one input and generalize the treatment of set operations
    if operation.is_a? Xplain::SetOperation
      operation_code = operation.class.name + ".new([#{parsed_inputs.join(", ")}])"
      return operation_code
    end
    
    if inputs.empty?
      operation_code = operation.class.name + ".new#{parse_operation_constructor(operation)}"
      return operation_code
    end
    operation_code << "#{parsed_inputs.first}." 
    operation_code << operation.class.name.gsub("Xplain::", "").to_underscore
    operation_code << "#{parse_operation_constructor(operation)}"
    
    if operation.auxiliar_function
      operation_code << " do\n"
      if operation.auxiliar_function.is_a? GenericFilter
        operation_code << parse_filter(operation.auxiliar_function)
      else
        operation_code << parse_auxiliary_function(operation.auxiliar_function)
      end
      operation_code << "\nend"
      
    end
    
    if operation.is_a?(Xplain::Pivot) && operation.relation 
      operation_code << " do\n" << parse_relation(operation.relation) << "\nend"
    end
      
    operation_code
  end
  
  def parse_operation_constructor(operation)
    parse_constructor_params operation.args
  end
  
  def parse_constructor_params(params)
    constructor_code = ""
    args_code = []
    if params.is_a? Hash
      params.each do |arg_name, arg_value|
        next if arg_name == :inputs
        args_code << "#{arg_name.to_s}: #{parse_arg(arg_value)}"
      end
    elsif params.respond_to? :each
      args_code += params.map{|arg_value| parse_arg(arg_value)}
    else
      args_code << parse_arg(params)
    end
    if !args_code.empty?
      constructor_code = "(#{args_code.join(", ")})"
    end
    constructor_code
  end
  
  def parse_arg(arg_value)
      if arg_value.is_a? Numeric
        arg_value.to_s
      elsif arg_value.is_a? String
        "'#{arg_value.to_s}'"
      elsif arg_value.is_a? Symbol
        ":#{arg_value}"
      else
        arg_value.to_s
      end 
  end
  
  def parse_filter(filter, spaces_count=2)
    parsed_filter = ""    
    if filter.is_a? RefineAux::CompositeFilter
      spaces_count.times{parsed_filter << " "}
      parsed_filter << "#{filter.class.name.gsub("RefineAux::", "")} do\n   [" << filter.filters.map do |child_filter|
        parse_filter child_filter, 4
      end.join(", ") << "\n"
      spaces_count.times{parsed_filter << " "}
      parsed_filter << "]\n"
      spaces_count.times{parsed_filter << " "}
      parsed_filter << "end"
    else
      parsed_filter << "\n"
      parsed_filter << parse_auxiliary_function(filter, spaces_count + 2)
      parsed_filter
    end
  end
  
  
  
  def parse_relation(relation, spaces_count = 2)
    parsed_relation = ""
    if relation.nil?
      return ""
    end
    if relation.is_a? Xplain::SchemaRelation
      parsed_relation = parse_schema_relation relation
    elsif relation.is_a? Xplain::ResultSet
      #TODO implement this step
    else
      parsed_relation = parse_path_relation(relation)
    end
    relation_code = ""
    spaces_count.times{relation_code << " "}
    relation_code << "relation " + parsed_relation
  end
  
  def parse_values(values, spaces_count=2)
    parsed_items_str = values.map do |value|
      parse_item value
    end.join(", ")
    values_clause = "\n"
    spaces_count.times{values_clause << " "}
    values_clause << 
      if values.first.is_a? Xplain::Entity
        if values.size > 1
          "entities " << parsed_items_str
        else
          "entity " << parsed_items_str
        end
      elsif values.first.is_a? Xplain::Literal
        if values.size > 1
          "literals " << parsed_items_str
        else
          "literal " << parsed_items_str
        end
      end
    values_clause
  end
  
  def parse_item(item)
    if item.is_a? Xplain::Entity
      "\"#{item.id}\""
    elsif item.is_a? Xplain::Literal
      "\"#{item.text}\"=>\"#{item.datatype}\""
    end
  end
  #private
  def parse_result_set(rs)
    "Xplain::ResultSet.load(\"#{rs.id}\")"
  end
 
  def parse_auxiliary_function(aux_func, spaces_count=2)
    aux_func_code = ""
    spaces_count.times{aux_func_code << " "}
    aux_func_code << aux_func.class.name.split("::").last.to_underscore
    if aux_func.args && !aux_func.args.empty?
      aux_func_code << parse_operation_constructor(aux_func)
    end
    #TODO for some functions the "do end" is not necessary. Eg. "set.xmap do count do end end" should be "set.xmap do count end" 
    aux_func_code << " do\n"
    if aux_func.respond_to?(:relation)
      aux_func_code << parse_relation(aux_func.relation, spaces_count + 2)
    end
    
    if aux_func.respond_to? :values
      aux_func_code << parse_values(aux_func.values, spaces_count + 2)
    end
    
    
    aux_func_code << "\n"
    spaces_count.times{aux_func_code << " "}
    aux_func_code << "end"
  end
  
  def parse_schema_relation(relation)
    r_id = "\"" + relation.id + "\""
    r_code = r_id  
    if relation.inverse?
      r_code = "inverse(#{r_id})"
    end
    r_code
  end
  
  def parse_refine_filter
    
  end

  def parse_path_relation(path_relation)
    relation_code = path_relation.map{|relation| parse_schema_relation relation}.join(", ")
    relation_code
  end
  
  def to_ruby(input, parse_recursive=true)
    if input.is_a? String
      return input
    end
    ruby_code = ""
    if input.is_a? Xplain::ResultSet
      ruby_code += parse_result_set input
    elsif input.is_a? Xplain::Operation
      ruby_code += parse_operation input, parse_recursive
    end
    ruby_code
  end
  
end