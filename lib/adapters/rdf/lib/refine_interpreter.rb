class SPARQLFilterInterpreter
  include SPARQLHelper
  @@accepted_filters =   ["RefineAux::And", "RefineAux::Or", "RefineAux::Equals", "RefineAux::Contains", "RefineAux::EqualsOne", "RefineAux::LessThan", "RefineAux::LessThanEqual", "RefineAux::GreaterThan", "RefineAux::GreaterThanEqual"]
  
  ACCEPT_PATH_QUERY = false
  ACCEPT_PATH_CLAUSE = false
    
  def initialize()
    @relations_index = 1
  end
  
  def filter(var, operator, value)
    parsed_item = if(value.is_a? Xplain::Literal)
      if !value.datatype.nil?
        "#{var} #{operator} #{parse_item(value)}"
      else
        "#{var} #{operator} \"#{value.value.to_s}\""
      end
      
    else
      
      "#{var} #{operator} #{parse_item(value)}"
    end
    
    parsed_item
  end
  
  def validate_filters(filter_expr, invalid_filters = [])
    invalid_filters << filter_expr if !@@accepted_filters.include?(filter_expr.class.name)
    if filter_expr.respond_to? :filters
      filter_expr.filters.each{|filter| validate_filters(filter, invalid_filters)}
    end
    return invalid_filters
  end
  
  def can_filter?(filter_expr)

    if filter_expr.respond_to? :filters
      return filter_expr.filters.inject(false){|boolean, filter| boolean || can_filter?(filter)}
    end

    return @@accepted_filters.include? filter_expr.class.name
  end
  
  
  def parse(f)

    filters = generate_filters(f)

    query = ""
    query << filters.keys.join(". ")
    filters_clauses = filters.values.flatten
    if(!filters_clauses.empty?)
      query << " FILTER(" + filters.values.flatten.join(" && ") + ")"
    end
    
    query
  end
      
  def generate_where_hash(relation, operator, value)
    hash = {}
    where = path_clause(relation, true)
    if relation
      hash[where] ||= []
      hash[where] << filter("?o", operator, value)
    else
#.*subject.*
    end
    hash
  end
  
  def generate_filters(f)

    hash = {}
    filter_clause = 
    if f.class.name == "RefineAux::Equals"
      
      generate_where_hash(f.relation, "=", f.values.first)
    elsif f.class.name == "RefineAux::Contains"
      if(f.respond_to? :relation)
        where_clause = "?s <#{f.relation}> ?o#{@relations_index+=1}"
       
        where_clause << " VALUES ?o#{@relations_index}{" + f.values.map{|item| parse_item(item)}.join(" ") + "}"
      else
        #TODO apply the filter to the subjects
      end 
      {where_clause => []}
      
    elsif f.class.name == "RefineAux::EqualsOne"

     if(f.respond_to? :relation)
       where_clause = "?s <#{f.relation}> ?o#{@relations_index+=1}"
       
       where_clause << " VALUES ?o#{@relations_index}{" + f.values.map{|item| parse_item(item)}.join(" ") + "}"
     else
      #TODO apply the filter to the subjects
     end 
     {where_clause => []}
    elsif f.class.name ==  "RefineAux::LessThan"
      generate_where_hash(f.relation, "<", f.values.first)
    elsif f.class.name == "RefineAux::LessThanEqual"
      generate_where_hash(f.relation, "<=", f.values.first)
    elsif f.class.name == "RefineAux::GreaterThan"
      generate_where_hash(f.relation, ">", f.values.first)
    elsif f.class.name == "RefineAux::GreaterThanEqual"
      generate_where_hash(f.relation, ">=", f.values.first)
    elsif f.class.name == "RefineAux::And"
      hash = {}
      where_clauses = []
      filters = []
      f.filters.each do |af|
        hash = generate_filters(af)
        hash.each do |where, where_filters|
          where_clauses << where.gsub("?o","?o#{@relations_index+=1}")
          filters << ("(" + where_filters.map{|c| c.gsub("?o", "?o#{@relations_index}")}.join(" && ") + ")")
        end

      end
      where_clause = where_clauses.join(". ") << " Filter(" + filters.join(" && ") + ")"
      {where_clause => []}    
      
    elsif f.class.name == "RefineAux::Or"
      hash = {}
      where_clauses = []

      filter_clause = ""
      f.filters.each do |af|
        hash.merge!(generate_filters(af)){|where, filters1, filters2| filters1 + filters2}
      end
#.*subject.*
      
      hash.each do |where, fclauses|

        where_copy = where.gsub("?o","?o#{@relations_index+=1}")
        filter_clause = "(" + fclauses.map{|c| c.gsub("?o", "?o#{@relations_index}")}.join(" || ") + ")"
        where_clauses << "{" + where_copy + ". FILTER(#{filter_clause})}"
      end

      where_clause = where_clauses.join(" UNION ") 
      {where_clause => []}    
    elsif f.class.name == "RefineAux::Not"
      {}
    else
      {}        
    end
    filter_clause
  end
end
