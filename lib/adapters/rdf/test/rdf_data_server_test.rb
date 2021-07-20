require './test/xplain_unit_test'
require 'rdf'
require 'sparql/client'


class RDFDataServerTest < XplainUnitTest
  
  def setup
    super()
    @xplain_ns = "http://tecweb.inf.puc-rio.br/xplain/"
    @rdf_ns = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    @dcterms = "http://purl.org/dc/terms/"
    @sparql_client = SPARQL::Client.new @graph
    Xplain.set_exploration_repository @server
    Xplain.set_default_server @server
    
  end
  
  def generate_insert_stmt(triple_array)
    numeric_props = ["index"]
    literal_props = [
      "title",
      "label_for",
      "inverse_label_for",
      "has_view_type",
      "item_type"
    ]
    
    insert_stmt = "INSERT DATA{"
    
    insert_stmt << triple_array.map do |triple|
      
      is_literal_prop = !literal_props.select{|prop| triple[1].include? prop}.empty?
      is_numeric_prop = !numeric_props.select{|prop| triple[1].include? prop}.empty?
      
      s = triple[0]
      p = triple[1]
      o = triple[2]
      o_str = if is_literal_prop
                "\"#{o}\""
              elsif is_numeric_prop
                o
              else
                "<#{o}>"
              end
      "<#{s}> <#{p}> #{o_str}"
    end.join(" . ")

    insert_stmt << "}"
    insert_stmt
  end

  def get_triples_set(sparql_query)
    Set.new get_triples_array sparql_query
  end

  def get_triples_array(sparql_query)
    triples_found = []
    @sparql_client.query(sparql_query).each do |sol|
      triples_found << [sol[:s].to_s, sol[:p].to_s, sol[:o].to_s]
    end
    triples_found.sort{|t1, t2| t1.inspect <=> t2.inspect}
  end
  
  
  def test_save_resultset_flat
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]    
    
    rs = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes)
    rs.save()
    
    expected_triples = []
    expected_triples << ["#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << ["#{@xplain_ns}np1", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}has_text", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]
    expected_triples << ["#{@xplain_ns}np2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}has_text", "_:p2"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"]
    
    sparql_query = "SELECT ?s ?p ?o WHERE{?s ?p ?o. values ?p{<#{@xplain_ns}included_in> <#{@xplain_ns}index>  <#{@xplain_ns}has_item> <#{@xplain_ns}has_text> <#{@rdf_ns}type>}.}"
    
    expected_triples.sort!{|t1, t2| t1.inspect <=> t2.inspect}
    actual_rs = get_triples_array(sparql_query).sort{|t1, t2| t1.inspect <=> t2.inspect}
    diff = "Difference: \n" << (expected_triples-actual_rs + actual_rs - expected_triples).inspect
    assert_equal expected_triples, actual_rs, "Difference: \n" << (expected_triples-actual_rs).inspect
    
  end


  def test_save_resultset_title_intention
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    resulted_from = Xplain::ResultSet.new(id: "#{@xplain_ns}resulted_from_set")
    operation = Xplain::KeywordSearch.new(inputs: [resulted_from], keyword_phrase:  'test_keyword')
    
    rs = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes, intention: operation, title: "title_set")
    
    rs.save()
    
    expected_triples = []
    expected_triples << [ "#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"]
    expected_triples << [ "#{@xplain_ns}test_id", "#{@xplain_ns}intention", "Xplain::ResultSet.load(\"#{@xplain_ns}resulted_from_set\").keyword_search(keyword_phrase: 'test_keyword')"]
    expected_triples << [ "#{@xplain_ns}test_id", "#{@dcterms}title", "title_set"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << ["#{@xplain_ns}np1", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}has_text", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}has_text", "_:p2"]
    expected_triples << ["#{@xplain_ns}np2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]
    
    sparql_query = "SELECT ?s ?p ?o WHERE{?s ?p ?o. values ?p{<#{@xplain_ns}resulted_from> <#{@xplain_ns}included_in> <#{@xplain_ns}has_text> <#{@xplain_ns}index> <#{@xplain_ns}has_item> <#{@dcterms}title> <#{@xplain_ns}intention> <#{@rdf_ns}type>}.}" 
    
    expected_triples.sort!{|t1, t2| t1.inspect <=> t2.inspect}
    actual_rs = get_triples_array(sparql_query).sort{|t1, t2| t1.inspect <=> t2.inspect}
    diff = "Difference: \n" << (expected_triples-actual_rs + actual_rs - expected_triples).inspect
    assert_equal expected_triples, actual_rs, "Difference: \n" << (expected_triples-actual_rs).inspect
  end
  
  def test_save_resultset_two_levels
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    
    rs = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes)
    rs.save()
    
    expected_triples = []
    expected_triples << ["#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"]
    expected_triples << ["#{@xplain_ns}np1", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.1"]
    
    expected_triples << [ "#{@xplain_ns}np1.1", "#{@xplain_ns}index", "1"]
    expected_triples << ["#{@xplain_ns}np1.1", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.2"]
    expected_triples << [ "#{@xplain_ns}np1.2", "#{@xplain_ns}index", "2"]
    expected_triples << [ "#{@xplain_ns}np1.2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << [ "#{@xplain_ns}np1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]
    expected_triples << [ "#{@xplain_ns}np1.1", "#{@xplain_ns}has_item", "_:p1.1"]
    expected_triples << [ "#{@xplain_ns}np1.2", "#{@xplain_ns}has_item", "_:p1.2"]
    
    sparql_query = "SELECT ?s ?p ?o WHERE{?s ?p ?o. values ?p{<#{@xplain_ns}included_in> <#{@xplain_ns}index>  <#{@xplain_ns}has_item> <#{@xplain_ns}children> <#{@rdf_ns}type>}}"
    
    expected_triples.sort!{|t1, t2| t1.inspect <=> t2.inspect}
    actual_rs = get_triples_array(sparql_query).sort{|t1, t2| t1.inspect <=> t2.inspect}
    diff = "Difference: \n" << (expected_triples-actual_rs + actual_rs - expected_triples).inspect
    assert_equal expected_triples, actual_rs, "Difference: \n" << (expected_triples-actual_rs).inspect
  end
  
  def test_save_same_item_two_rs_flat
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]

    input_nodes2 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1rs2"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2rs2")
    ]
    
    rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id1", nodes: input_nodes)
    rs2 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id2", nodes: input_nodes2)
    rs1.save
    rs2.save
    
    expected_triples = []
    expected_triples << ["#{@xplain_ns}test_id1", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"]
    expected_triples << ["#{@xplain_ns}test_id2", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id1"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"]
    expected_triples << ["#{@xplain_ns}np1", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id1"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"]
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}index", "1"]
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np2rs2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"]
    expected_triples << [ "#{@xplain_ns}np2rs2", "#{@xplain_ns}index", "2"]
    expected_triples << ["#{@xplain_ns}np2rs2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]
    
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}has_item", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np2rs2", "#{@xplain_ns}has_item", "_:p2"]

    sparql_query = "SELECT ?s ?p ?o WHERE{?s ?p ?o. values ?p{<#{@xplain_ns}included_in> <#{@xplain_ns}index>  <#{@xplain_ns}has_item> <#{@xplain_ns}children> <#{@rdf_ns}type>}}"
    expected_triples.sort!{|t1, t2| t1.inspect <=> t2.inspect}
    actual_rs = get_triples_array(sparql_query).sort{|t1, t2| t1.inspect <=> t2.inspect}
    diff = "Difference: \n" << (expected_triples-actual_rs + actual_rs - expected_triples).inspect
    assert_equal expected_triples, actual_rs, "Difference: \n" << (expected_triples-actual_rs).inspect
  end
  
  def test_save_same_item_two_rs_two_level
    types = [Xplain::Type.new(id: "#{@xplain_ns}Type1"), Xplain::Type.new(id: "#{@xplain_ns}Type2")]
    input_nodes1 = [
      Xplain::Node.new(item: Xplain::Entity.new(id: "_:p1", types: types), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes1.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    input_nodes2 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1rs2"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p3"), id: "#{@xplain_ns}np3")
    ]
    input_nodes2.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1rs2"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2rs2")]
    
    rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id1", nodes: input_nodes1)
    rs2 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id2", nodes: input_nodes2)
    rs1.save
    rs2.save
    
    expected_triples = []
    expected_triples << ["#{@xplain_ns}test_id1", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"]
    expected_triples << ["#{@xplain_ns}test_id2", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"]
    expected_triples << ["_:p1", "#{@rdf_ns}type", "#{@xplain_ns}Type1"]
    expected_triples << ["_:p1", "#{@rdf_ns}type", "#{@xplain_ns}Type2"]

    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id1"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"]
    expected_triples << ["#{@xplain_ns}np1", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.1"]
    expected_triples << [ "#{@xplain_ns}np1.1", "#{@xplain_ns}index", "1"]
    expected_triples << ["#{@xplain_ns}np1.1", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id1"]
    expected_triples << ["#{@xplain_ns}np1.2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id1"]
    expected_triples << [ "#{@xplain_ns}np1.2", "#{@xplain_ns}index", "2"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.2"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id1"]
    expected_triples << ["#{@xplain_ns}np2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"]
    expected_triples << [ "#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]
    expected_triples << [ "#{@xplain_ns}np1.1", "#{@xplain_ns}has_item", "_:p1.1"]
    expected_triples << [ "#{@xplain_ns}np1.2", "#{@xplain_ns}has_item", "_:p1.2"]

    
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"]
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}index", "1"]
    expected_triples << ["#{@xplain_ns}np1rs2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}children", "#{@xplain_ns}np1.1rs2"]
    expected_triples << [ "#{@xplain_ns}np1.1rs2", "#{@xplain_ns}index", "1"]
    expected_triples << ["#{@xplain_ns}np1.1rs2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1.1rs2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"]
    expected_triples << [ "#{@xplain_ns}np1.2rs2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"]
    expected_triples << [ "#{@xplain_ns}np1.2rs2", "#{@xplain_ns}index", "2"]
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}children", "#{@xplain_ns}np1.2rs2"]
    expected_triples << [ "#{@xplain_ns}np3", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"]
    expected_triples << [ "#{@xplain_ns}np3", "#{@xplain_ns}index", "2"]
    expected_triples << ["#{@xplain_ns}np3", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    expected_triples << [ "#{@xplain_ns}np1rs2", "#{@xplain_ns}has_item", "_:p1"]
    expected_triples << [ "#{@xplain_ns}np3", "#{@xplain_ns}has_item", "_:p3"]
    expected_triples << [ "#{@xplain_ns}np1.1rs2", "#{@xplain_ns}has_item", "_:p1.1"]
    expected_triples << [ "#{@xplain_ns}np1.2rs2", "#{@xplain_ns}has_item", "_:p1.2"]
    expected_triples << ["#{@xplain_ns}np1.2rs2", "#{@rdf_ns}type", "#{@xplain_ns}Node"]
    
    sparql_query = "SELECT ?s ?p ?o WHERE{ ?s ?p ?o. values ?p{<#{@xplain_ns}included_in> <#{@xplain_ns}index> <#{@xplain_ns}has_item> <#{@xplain_ns}children> <#{@rdf_ns}type>}}"
    
    actual_rs = get_triples_array(sparql_query).sort{|t1, t2| t1.inspect <=> t2.inspect}
    expected_triples.sort!{|t1, t2| t1.inspect <=> t2.inspect}
    diff = "Difference: \n" << (expected_triples-actual_rs + actual_rs - expected_triples).inspect
    diff = "Difference: \n" << (expected_triples-actual_rs + actual_rs - expected_triples).inspect
    assert_equal expected_triples, actual_rs, "Difference: \n" << (expected_triples-actual_rs).inspect
  end

  def test_load_flat_rs
    types = [Xplain::Type.new(id: "xplain:Type1"), Xplain::Type.new(id: "xplain:Type2")]

    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(id: "_:p1", types: types), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new(id: "_:p2", types: types), id: "#{@xplain_ns}np2")
    ]

    
    input_rs = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes)
    input_rs.save()
    
    expected_rs = Xplain::ResultSet.load("#{@xplain_ns}test_id")
    
    assert_same_result_set input_rs, expected_rs
    p1 = expected_rs.nodes.select{|n| n.item.id =="_:p1"}.first()
    p2 = expected_rs.nodes.select{|n| n.item.id =="_:p2"}.first()

    actual_types_p1 = Set.new(p1.item.types)
    actual_types_p2 = Set.new(p2.item.types)
    
    assert_equal Set.new(types), actual_types_p1
    assert_equal Set.new(types), actual_types_p2

    

  end
  
  def test_load_flat_rs_intention
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    resulted_from = Xplain::ResultSet.new(id: "#{@xplain_ns}resulted_from_set", nodes: [Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}nprs1")])
    resulted_from.save
    operation = Xplain::KeywordSearch.new(inputs: [resulted_from], keyword_phrase:  'test_keyword')
    input_rs = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes, intention: operation, title: "title_set")
    input_rs.save()
    
    expected_rs = Xplain::ResultSet.load("#{@xplain_ns}test_id")
    
    assert_same_result_set input_rs, expected_rs
    dsl_parser = DSLParser.new
    assert_equal dsl_parser.to_ruby(expected_rs.intention), "Xplain::ResultSet.load(\"#{@xplain_ns}resulted_from_set\").keyword_search(keyword_phrase: 'test_keyword')"
    assert_same_result_set_no_title expected_rs.intention.inputs.first, resulted_from

  end

  def test_load_flat_two_rs
    input_nodes1 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    input_nodes2 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1rs2"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p3"), id: "#{@xplain_ns}np3")
    ]
    rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id1", nodes: input_nodes1)
    rs2 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id2", nodes: input_nodes2)
    rs1.save
    rs2.save
    
    loaded_rs1 = Xplain::ResultSet.load("#{@xplain_ns}test_id1")
    loaded_rs2 = Xplain::ResultSet.load("#{@xplain_ns}test_id2")
    
    assert_same_result_set rs1, loaded_rs1
    assert_same_result_set rs2, loaded_rs2

  end
  
  def test_load_flat_rs_multilevel
    input_nodes1 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes1.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    
    rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id1", nodes: input_nodes1)
    rs1.save
    
    loaded_rs1 = Xplain::ResultSet.load("#{@xplain_ns}test_id1")

    
    assert_same_result_set rs1, loaded_rs1

  end

  def test_load_two_rs_two_level
    input_nodes1 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes1.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    input_nodes2 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1rs2"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p3"), id: "#{@xplain_ns}np3")
    ]
    input_nodes2.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1rs2"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2rs2")]
    
    rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id1", nodes: input_nodes1)
    rs2 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id2", nodes: input_nodes2)
    rs1.save
    rs2.save
    
    loaded_rs1 = Xplain::ResultSet.load("#{@xplain_ns}test_id1")
    loaded_rs2 = Xplain::ResultSet.load("#{@xplain_ns}test_id2")
    
    assert_same_result_set rs1, loaded_rs1
    assert_same_result_set rs2, loaded_rs2
  end
  
  def test_load_level3_set
    input_nodes1 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes1.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    input_nodes1[1].children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1"), id: "#{@xplain_ns}np2.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p2.2"), id: "#{@xplain_ns}np2.2")]
    
    #setting level 3
    input_nodes1.first.children.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1.1"), id: "#{@xplain_ns}np1.1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.1.2"), id: "#{@xplain_ns}np1.1.2")]
    
    rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id1", nodes: input_nodes1)
    rs1.save
    
    loaded_rs1 = Xplain::ResultSet.load("#{@xplain_ns}test_id1")

    
    assert_same_result_set rs1, loaded_rs1
  end
  
  def test_remove_set
    insert_rs = "INSERT DATA{ <#{@xplain_ns}test_id2> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id2> <#{@dcterms}title> \"Set 2\". }"
    rs2_triples = [
      ["#{@xplain_ns}test_id2", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id2", "#{@dcterms}title", "Set 2"]
    ]
    items_rs2_triples = [
      ["#{@xplain_ns}npt1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1.1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.1"],
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1.2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}has_item", "_:p2"]
    ]
    
    insert_items = "INSERT DATA{#{items_rs2_triples.map{|triple| triple.map{|r| "<#{r}>"}.join(" ")}.join(".")} }"
    @sparql_client.update(insert_rs)
    @sparql_client.update(insert_items)

    insert_rs = "INSERT DATA{ <#{@xplain_ns}test_id> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id> <#{@dcterms}title> \"Set 1\". }"
    rs_triples = [
      ["#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id", "#{@dcterms}title", "Set 1"]
    ]
    items_triples = [
      ["#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1.1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.1"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1.2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.2"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]
    ]
    
    insert_items = "INSERT DATA{#{items_triples.map do|triple| 
      triple.map do |r|
        if r == triple.last && triple[1].include?("index") 
          r
        else
          "<#{r}>"
        end
      end.join(" ")
    end.join(".")} }"
    @sparql_client.update(insert_rs)
    @sparql_client.update(insert_items)

     input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    
    rs = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes, title: "Set 1")

    rs.delete

    all_triples = get_triples_array("SELECT * WHERE{?s ?p ?o}")
    triples_to_remove = rs_triples + items_triples
    intersection = all_triples & triples_to_remove
    assert_true intersection.empty?, "TRIPLES NOT REMOVED: \n  " << intersection.inspect
    rs2_all_triples = rs2_triples + items_rs2_triples
    
    intersection = all_triples & rs2_all_triples
    
    assert_equal Set.new(intersection), Set.new(rs2_all_triples), "TRIPLES THAT SHOULDN'T BE REMOVED: \n  " << (rs2_all_triples - intersection).inspect
  end
  
  def test_load_all_resultsets
    insert_rs = "INSERT DATA{ <#{@xplain_ns}test_id2> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id2> <#{@dcterms}title> \"Set 2\". }"
    rs2_triples = [
      ["#{@xplain_ns}test_id2", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id2", "#{@dcterms}title", "Set 2"]
    ]
    items_rs2_triples = [
      ["#{@xplain_ns}npt1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1", "#{@xplain_ns}index", "1"],
      [ "#{@xplain_ns}npt1", "#{@dcterms}title", "_:p1"], 
      ["#{@xplain_ns}npt1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1.1", "#{@xplain_ns}index", "1"],
      [ "#{@xplain_ns}npt1.1", "#{@dcterms}title", "_:p1.1"],
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.1"], 
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1.2", "#{@xplain_ns}index", "2"],
      [ "#{@xplain_ns}npt1.2", "#{@dcterms}title", "_:p1.2"], 
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt2", "#{@xplain_ns}index", "2"],
      [ "#{@xplain_ns}npt2", "#{@dcterms}title", "_:p2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}has_item", "_:p2"]
    ]
    
    insert_items = "INSERT DATA{#{items_rs2_triples.map do|triple| 
      triple.map do |r|
        if r == triple.last && triple[1].include?("index") 
          r
        else
          "<#{r}>"
        end
      end.join(" ")
    end.join(".")} }"

    @sparql_client.update(insert_rs)
    @sparql_client.update(insert_items)

    insert_rs = "INSERT DATA{ <#{@xplain_ns}test_id> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id> <#{@dcterms}title> \"Set 1\". }"
    rs_triples = [
      ["#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id", "#{@dcterms}title", "Set 1"]
    ]
    items_triples = [
      ["#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"],
      [ "_:p1", "#{@dcterms}title", "_:p1"],
      [ "_:p1", "#{@xplain_ns}item_type", "Xṕlain::Entity"], 
      ["#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1.1", "#{@xplain_ns}index", "1"],
      [ "_:p1.1", "#{@dcterms}title", "_:p1.1"], 
      [ "_:p1.1", "#{@xplain_ns}item_type", "Xṕlain::Entity"],
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.1"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1.2", "#{@xplain_ns}index", "2"],
      [ "_:p1.2", "#{@dcterms}title", "_:p1.2"],
      [ "_:p1.2", "#{@xplain_ns}item_type", "Xṕlain::Entity"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.2"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"],
      [ "_:p2", "#{@dcterms}title", "_:p2"],
      [ "_:p2", "#{@xplain_ns}item_type", "Xṕlain::Entity"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]
    ]
    
    insert_items = "INSERT DATA{#{items_triples.map do|triple| 
      triple.map do |r|
        if r == triple.last && triple[1].include?("index") 
          r
        else
          "<#{r}>"
        end
      end.join(" ")
    end.join(".")} }"

    @sparql_client.update(insert_rs)
    @sparql_client.update(insert_items)
    
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    
    expected_rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes, title: "Set 1")
    
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}npt1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}npt2")
    ]
    
    input_nodes.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}npt1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}npt1.2")]
    
    expected_rs2 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id2", nodes: input_nodes, title: "Set 2")
    
    all_sets = Xplain::ResultSet.load_all
    actual_rs1, actual_rs2 = all_sets.select{|s| s.id == "#{@xplain_ns}test_id"}.first, all_sets.select{|s| s.id == "#{@xplain_ns}test_id2"}.first
    assert_same_result_set actual_rs1, expected_rs1
    assert_same_result_set actual_rs2, expected_rs2
 
  end
  
  def test_load_all_topological_ordered
    insert_stmt = "INSERT DATA{\n 
    <#{@xplain_ns}test_id> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id> <#{@dcterms}title> \"Set 1\".\n\n 
    <#{@xplain_ns}test_id> <#{@xplain_ns}intention> \"Xplain::KeywordSearch.new(keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id2> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id2> <#{@dcterms}title> \"Set 2\". \n\n
    <#{@xplain_ns}test_id2> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id').keyword_search(keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id3> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id3> <#{@dcterms}title> \"Set 3\".\n\n
    <#{@xplain_ns}test_id3> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id2').keyword_search(keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id3.1> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id3.1> <#{@dcterms}title> \"Set 3.1\".\n\n
    <#{@xplain_ns}test_id3.1> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id3').keyword_search(keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id3.2> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id3.2> <#{@dcterms}title> \"Set 3.2\".\n\n
    <#{@xplain_ns}test_id3.2> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id3').keyword_search(keyword_phrase: 'test')\".\n\n
    }"
    
    @sparql_client.update(insert_stmt)
    
    actual_sets = Xplain::ResultSet.load_all_tsorted().map{|rs| rs.id}
    expected_sets = ["#{@xplain_ns}test_id", "#{@xplain_ns}test_id2", "#{@xplain_ns}test_id3","#{@xplain_ns}test_id3.1", "#{@xplain_ns}test_id3.2"]
    alt_expected_sets = ["#{@xplain_ns}test_id", "#{@xplain_ns}test_id2", "#{@xplain_ns}test_id3","#{@xplain_ns}test_id3.2", "#{@xplain_ns}test_id3.1"]
    
    assert_true((expected_sets == actual_sets || alt_expected_sets == actual_sets), "ACTUAL SETS: \n  " << actual_sets.inspect )

 
  end
  
  def test_load_exploration_only
    insert_stmt = "INSERT DATA{\n 
    <#{@xplain_ns}test_id> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id> <#{@dcterms}title> \"Set 1\".\n\n 
    <#{@xplain_ns}test_id> <#{@xplain_ns}intention> \"Xplain::KeywordSearch.new(keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id2> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id2> <#{@dcterms}title> \"Set 2\". \n\n
    <#{@xplain_ns}test_id2> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id').keyword_search(keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id3> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id3> <#{@dcterms}title> \"Set 3\".\n\n
    <#{@xplain_ns}test_id3> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id2').keyword_search(keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id3.1> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id3.1> <#{@dcterms}title> \"Set 3.1\".\n\n
    <#{@xplain_ns}test_id3.1> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id3').keyword_search(visual:    true, keyword_phrase: 'test')\".\n\n
    
    <#{@xplain_ns}test_id3.2> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id3.2> <#{@dcterms}title> \"Set 3.2\".\n\n
    <#{@xplain_ns}test_id3.2> <#{@xplain_ns}intention> \"Xplain::ResultSet.load('#{@xplain_ns}test_id3').keyword_search(keyword_phrase: 'test')\".\n\n
    }"
    
    @sparql_client.update(insert_stmt)
    
    actual_sets = Xplain::ResultSet.load_all_tsorted_exploration_only().map{|rs| rs.id}
    expected_sets = ["#{@xplain_ns}test_id", "#{@xplain_ns}test_id2", "#{@xplain_ns}test_id3", "#{@xplain_ns}test_id3.2"]
    alt_expected_sets = ["#{@xplain_ns}test_id", "#{@xplain_ns}test_id2", "#{@xplain_ns}test_id3","#{@xplain_ns}test_id3.2"]
    
    assert_true((expected_sets == actual_sets || alt_expected_sets == actual_sets), "ACTUAL SETS: \n  " << actual_sets.inspect )

    
  end
  
  #TODO Finish this test
  def test_load_ordered_result_set
        insert_rs = "INSERT DATA{ <#{@xplain_ns}test_id2> <#{@rdf_ns}type> <#{@xplain_ns}ResultSet>.
    <#{@xplain_ns}test_id2> <#{@dcterms}title> \"Set 2\". }"
    rs2_triples = [
      ["#{@xplain_ns}test_id2", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id2", "#{@dcterms}title", "Set 2"]
    ]
    items_rs2_triples = [
      ["#{@xplain_ns}npt2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt2", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}has_item", "_:p2"],
      ["#{@xplain_ns}npt2.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt2.2", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt2.2", "#{@xplain_ns}has_item", "_:p2.2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.1"],
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1.2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.2"],
      [ "#{@xplain_ns}npt1", "#{@xplain_ns}index", "2"],
      ["#{@xplain_ns}npt2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      ["#{@xplain_ns}npt2", "#{@xplain_ns}has_item", "_:p2"]
    ]
    
    insert_items = "INSERT DATA{#{items_rs2_triples.map do|triple| 
      triple.map do |r|
        if r == triple.last && triple[1].include?("index") 
          r
        else
          "<#{r}>"
        end
      end.join(" ")
    end.join(".")} }"

    @sparql_client.update(insert_rs)
    @sparql_client.update(insert_items)
    
    assert true

  end
  
  def test_save_session
    input_nodes1 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes1.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    input_nodes2 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}npt1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}npt2")
    ]
    input_nodes2.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}npt1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}npt1.2")]
    
    rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes1)
    rs1.save
    session = Xplain::Session.new(id: "#{@xplain_ns}test_session", server: @server)
    session << rs1
    
    rs2 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id2", nodes: input_nodes2)
    rs2.save
    session << rs2
    
    rs1_triples = [
      ["#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id", "#{@dcterms}title", "Set 1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1.1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.1"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np1.2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.2"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]

    ]
    rs2_triples = [
      ["#{@xplain_ns}test_id2", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id2", "#{@dcterms}title", "Set 2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1.1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.1"],
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt1.2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      [ "#{@xplain_ns}npt2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}has_item", "_:p2"]
    ]
    session_triples = [
      ["#{@xplain_ns}test_session", "#{@rdf_ns}type", "#{@xplain_ns}Session"],
      ["#{@xplain_ns}test_session", "#{@xplain_ns}contains_set", "#{@xplain_ns}test_id"],
      ["#{@xplain_ns}test_session", "#{@xplain_ns}contains_set", "#{@xplain_ns}test_id2"]
    ]
    
    expected_triples = (session_triples + rs1_triples + rs2_triples).sort{|t1, t2| t1.to_s <=> t2.to_s}
    all_triples = get_triples_array("SELECT * WHERE{?s ?p ?o}").sort{|t1, t2| t1.to_s <=> t2.to_s}
    
    assert_equal expected_triples, expected_triples & all_triples, "Difference: \n" << (expected_triples - all_triples).inspect
 
  end
  

  
  def test_load_session
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}np2")
    ]
    
    input_nodes.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}np1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}np1.2")]
    
    expected_rs1 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes, title: "Set 1")
    
    input_nodes2 = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1"), id: "#{@xplain_ns}npt1"),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"), id: "#{@xplain_ns}npt2")
    ]
    
    input_nodes2.first.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"), id: "#{@xplain_ns}npt1.1"), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"), id: "#{@xplain_ns}npt1.2")]
    
    expected_rs2 = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id2", nodes: input_nodes2, title: "Set 2")

    rs1_triples = [
      ["#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id", "#{@dcterms}title", "Set 1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      ["_:p1", "#{@dcterms}title", "_:p1"],
      ["_:p1", "#{@xplain_ns}item_type", "Xplain::Entity"],
      [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      ["#{@xplain_ns}np1.1", "#{@dcterms}title", "_:p1.1"],
      ["_:p1.1", "#{@xplain_ns}item_type", "Xplain::Entity"],
      [ "#{@xplain_ns}np1.1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.1"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      ["#{@xplain_ns}np1.2", "#{@dcterms}title", "_:p12"],
      [ "#{@xplain_ns}np1.2", "#{@xplain_ns}index", "2"],
      ["_:p1.2", "#{@xplain_ns}item_type", "Xplain::Entity"], 
      ["#{@xplain_ns}np1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.2"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      ["#{@xplain_ns}np2", "#{@dcterms}title", "_:p2"],
      [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"],
      ["_:p2", "#{@xplain_ns}item_type", "Xplain::Entity"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]

    ]
    rs2_triples = [
      ["#{@xplain_ns}test_id2", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id2", "#{@dcterms}title", "Set 2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      ["_:p1", "#{@dcterms}title", "_:p1"],
      ["_:p1", "#{@xplain_ns}item_type", "Xplain::Entity"],
      [ "#{@xplain_ns}npt1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      ["_:p1.1", "#{@dcterms}title", "_:p1.1"],
      ["_:p1.1", "#{@xplain_ns}item_type", "Xplain::Entity"],
      [ "#{@xplain_ns}npt1.1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}npt1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.1"],
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      ["_:p1.2", "#{@dcterms}title", "_:p1.2"],
      ["_:p1.2", "#{@xplain_ns}item_type", "Xplain::Entity"],
      [ "#{@xplain_ns}npt1.2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}npt1.2", "#{@xplain_ns}has_item", "_:p1.2"],
      ["#{@xplain_ns}npt1", "#{@xplain_ns}children", "#{@xplain_ns}npt1.2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id2"],
      ["_:p2", "#{@dcterms}title", "_:p2"],
      ["_:p2", "#{@xplain_ns}item_type", "Xplain::Entity"],
      [ "#{@xplain_ns}npt2", "#{@xplain_ns}index", "2"], 
      ["#{@xplain_ns}npt2", "#{@xplain_ns}has_item", "_:p2"]
    ]
    session_triples = [
      ["#{@xplain_ns}test_session", "#{@rdf_ns}type", "#{@xplain_ns}Session"],
      ["#{@xplain_ns}test_session", "#{@dcterms}title", "test session"],
      ["#{@xplain_ns}test_session", "#{@xplain_ns}contains_set", "#{@xplain_ns}test_id"],
      ["#{@xplain_ns}test_session", "#{@xplain_ns}contains_set", "#{@xplain_ns}test_id2"]
    ]
    
    session_rs_triples = session_triples + rs1_triples + rs2_triples
    sparql_insert = generate_insert_stmt(session_rs_triples)
    
    @sparql_client.update(sparql_insert)
    
    session_found = Xplain::Session.find_by_title("test session").first
    
    assert_false session_found.nil?
    assert_equal "test session", session_found.title
    assert_equal "xplain:test_session", session_found.id
    assert_equal 2, session_found.each_result_set_tsorted.size
    
    rs1 = session_found.each_result_set_tsorted.select{|rs| rs.id == "#{@xplain_ns}test_id"}.first
    rs2 = session_found.each_result_set_tsorted.select{|rs| rs.id == "#{@xplain_ns}test_id2"}.first
    assert_same_result_set expected_rs1, rs1
    assert_same_result_set expected_rs2, rs2
     
  end
  
  def test_list_session_titles
    
    insert_data = "INSERT DATA{
      <#{@xplain_ns}test_session> <#{@rdf_ns}type> <#{@xplain_ns}Session>.
      <#{@xplain_ns}test_session> <#{@dcterms}title> \"test session\".
      <#{@xplain_ns}test_session2> <#{@rdf_ns}type> <#{@xplain_ns}Session>.
      <#{@xplain_ns}test_session2> <#{@dcterms}title> \"test session 2\".
    }"
    
    @sparql_client.update(insert_data)
    
    session_names = Set.new(Xplain::Session.list_titles)
    
    assert_equal Set.new(["test session", "test session 2"]), session_names

  end

  def test_save_view_profile_labels_for_type
    current_profile = Xplain::Visualization::Profile.new(id: "#{@xplain_ns}test_profile")
    current_profile.label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "dcterms:title"
    current_profile.label_for_type "foaf:Agent", "foaf:name", "foaf:givenName"
    current_profile.save

    expected_triples = Set.new([
      ["#{@xplain_ns}test_profile", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile", "#{@dcterms}title", "test profile"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://www.w3.org/2000/01/rdf-schema#Resource<=>#{@dcterms}title"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://xmlns.com/foaf/0.1/Agent<=>http://xmlns.com/foaf/0.1/name<=>http://xmlns.com/foaf/0.1/givenName"],
    ])
    actual_triples = get_triples_set("SELECT * WHERE {?s ?p ?o. <#{@xplain_ns}test_profile> ?p ?o}")
    
    assert_equal expected_triples, actual_triples

  end

  def test_save_view_profile_label_for_relation
    current_profile = Xplain::Visualization::Profile.new(id: "#{@xplain_ns}test_profile")
    current_profile.text_for "#{@dcterms}title", "Título"
    current_profile.inverse_relation_text_for "#{@rdf_ns}type", "type of"
    current_profile.save
    expected_triples = Set.new(
      [
        ["#{@xplain_ns}test_profile", "#{@xplain_ns}label_for", "#{@dcterms}title<=>Título"],
        ["#{@xplain_ns}test_profile", "#{@xplain_ns}inverse_label_for", "#{@rdf_ns}type<=>type of"],
      ]
    )
    actual_triples = get_triples_set("SELECT * WHERE {?s ?p ?o. VALUES ?s{<#{@xplain_ns}test_profile>}. VALUES ?p{<#{@xplain_ns}label_for> <#{@xplain_ns}inverse_label_for>}}")
    assert_equal expected_triples, actual_triples
  end

  def test_create_profile
    params = {
      :id => "#{@xplain_ns}test_profile",
      :name => "test_profile",
      :labels_by_type_dict => {
        "http://www.w3.org/2000/01/rdf-schema#Resource" => ["dcterms:title", "#{@rdf_ns}label"],
        
      },
      :item_text_dict => {
        "#{@dcterms}title" => "Título"        
      },
      :inverse_relation_text_dict => {
        "#{@rdf_ns}type" => "type of"
      }
    }
    profile = Xplain::Visualization::Profile.create(params)
    expected_triples = Set.new([
      ["#{@xplain_ns}test_profile", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile", "#{@dcterms}title", "test_profile"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://www.w3.org/2000/01/rdf-schema#Resource<=>#{@dcterms}title<=>#{@rdf_ns}label"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}label_for", "#{@dcterms}title<=>Título"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}inverse_label_for", "#{@rdf_ns}type<=>type of"],
    ])
    actual_triples = get_triples_set("SELECT * WHERE {?s ?p ?o. <#{@xplain_ns}test_profile> ?p ?o}")
    assert_equal expected_triples, actual_triples
  end

  def test_load_profile
    profile_triples_to_insert = [
      ["#{@xplain_ns}test_profile", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile", "#{@dcterms}title", "test_profile"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://www.w3.org/2000/01/rdf-schema#Resource<=>#{@dcterms}title<=>#{@rdf_ns}label"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}label_for", "#{@dcterms}title<=>Título"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}inverse_label_for", "#{@rdf_ns}type<=>type of"],
    ]
    insert = generate_insert_stmt(profile_triples_to_insert)
    @sparql_client.update(insert)

    profile = Xplain::Visualization::Profile.load("xplain:test_profile")
    assert_false profile.nil?
    assert_equal "test_profile", profile.name
    assert_equal ["#{@dcterms}title", "#{@rdf_ns}label"], profile.labels_by_type_dict["http://www.w3.org/2000/01/rdf-schema#Resource"]
    assert_equal "Título", profile.item_text_dict["#{@dcterms}title"]
    assert_equal "type of", profile.inverse_relation_text_dict["#{@rdf_ns}type"]
  end

  def test_load_profile_by_name
    profile_triples_to_insert = [
      ["#{@xplain_ns}test_profile", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile", "#{@dcterms}title", "test_profile"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://www.w3.org/2000/01/rdf-schema#Resource<=>#{@dcterms}title<=>#{@rdf_ns}label"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}label_for", "#{@dcterms}title<=>Título"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}inverse_label_for", "#{@rdf_ns}type<=>type of"],
    ]
    insert = generate_insert_stmt(profile_triples_to_insert)
    @sparql_client.update(insert)

    profile = Xplain::Visualization::Profile.find_by_name("test_profile").first
    assert_false profile.nil?
    assert_equal "test_profile", profile.name
    assert_equal ["#{@dcterms}title", "#{@rdf_ns}label"], profile.labels_by_type_dict["http://www.w3.org/2000/01/rdf-schema#Resource"]
    assert_equal "Título", profile.item_text_dict["#{@dcterms}title"]
    assert_equal "type of", profile.inverse_relation_text_dict["#{@rdf_ns}type"]
  end

  def test_list_profiles
    profile_triples_to_insert = [
      ["#{@xplain_ns}test_profile", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile", "#{@dcterms}title", "test_profile"],
      ["#{@xplain_ns}test_profile2", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile2", "#{@dcterms}title", "test_profile2"],
      ["#{@xplain_ns}test_profile3", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile3", "#{@dcterms}title", "test_profile3"],

    ]
    insert = generate_insert_stmt(profile_triples_to_insert)
    @sparql_client.update(insert)
    profiles = Xplain::Visualization::Profile.list
    assert_equal 3, profiles.size
    assert_equal ["xplain:test_profile", "xplain:test_profile2", "xplain:test_profile3"], profiles.map{|p|p.id}
  end

  # def test_sample_type()
    # profile_triples_to_insert = [
      # ["#{@xplain_ns}test_item1", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      # ["#{@xplain_ns}test_item1", "#{@rdf_ns}type", "#{@xplain_ns}Type1"],
      # ["#{@xplain_ns}test_item2", "#{@rdf_ns}type", "#{@xplain_ns}Type2"],
    # ]
    # insert = generate_insert_stmt(profile_triples_to_insert)
# 
    # @sparql_client.update(insert)
    # 
    # expected_types = ["#{@xplain_ns}ViewProfile", "#{@xplain_ns}Type1", "#{@xplain_ns}Type2" ]
# 
    # actual_types = @server.sample_type([Xplain::Item.new(id: "#{@xplain_ns}test_item1"), Xplain::Item.new(id: "#{@xplain_ns}test_item2")], "#{@rdf_ns}type")
    # 
    # assert_equal expected_types, actual_types
  # end

  def test_restricted_image_with_types
    profile_triples_to_insert = [
      ["#{@xplain_ns}test_item1", "#{@xplain_ns}test_rel", "#{@xplain_ns}test_item2"],
      ["#{@xplain_ns}test_item2", "#{@xplain_ns}test_rel", "#{@xplain_ns}test_item3"],

      ["#{@xplain_ns}test_item2", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_item2", "#{@rdf_ns}type", "#{@xplain_ns}Type1"],
      ["#{@xplain_ns}test_item3", "#{@rdf_ns}type", "#{@xplain_ns}Type2"],
    ]
    insert = generate_insert_stmt(profile_triples_to_insert)

    @sparql_client.update(insert)

    expected_types = Set.new(["xplain:ViewProfile", "xplain:Type1", "xplain:Type2" ])
    domain_nodes = create_nodes [Xplain::Entity.new(id: "#{@xplain_ns}test_item1"), Xplain::Entity.new(id: "#{@xplain_ns}test_item2")]
    result_set = @server.restricted_image(Xplain::SchemaRelation.new(id: "#{@xplain_ns}test_rel"), domain_nodes)
    
    actual_types = []
    result_set.nodes.each{|n| actual_types += n.item.types.map{|t| t.id}}
    
    assert_equal expected_types, Set.new(actual_types)
    

  end

  def test_save_result_set_items_server

    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(id: "_:p1", types: [Xplain::Type.new("Type1")]), id: "#{@xplain_ns}np1"),
      Xplain::Node.new(item: Xplain::Entity.new(id: "_:p2", types: [Xplain::Type.new("Type2")]), id: "#{@xplain_ns}np2")
    ]    
    
    rs = Xplain::ResultSet.new(id: "#{@xplain_ns}test_id", nodes: input_nodes)
    rs.save()
    
    expected_triples = Set.new
    expected_triples << ["_:p1", "#{@xplain_ns}has_server", "default"]
    expected_triples << ["_:p2", "#{@xplain_ns}has_server", "default"]

    sparql_query = "SELECT ?s ?p ?o WHERE{?s ?p ?o. values ?p{ <#{@xplain_ns}has_server> }.}"
    
    assert_equal expected_triples, get_triples_set(sparql_query)
  
  end

  def test_load_result_set_with_view_profile
    rs1_triples = [
      ["#{@xplain_ns}test_id", "#{@rdf_ns}type", "#{@xplain_ns}ResultSet"],
      ["#{@xplain_ns}test_id", "#{@dcterms}title", "Set 1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      ["_:p1", "#{@dcterms}title", "_:p1"],
      ["_:p1", "#{@xplain_ns}item_type", "Xplain::Entity"],
      ["_:p1", "#{@rdf_ns}type", "#{@xplain_ns}Type1"],

      [ "#{@xplain_ns}np1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1", "#{@xplain_ns}has_item", "_:p1"],
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      ["#{@xplain_ns}np1.1", "#{@dcterms}title", "_:p1.1"],
      ["_:p1.1", "#{@xplain_ns}item_type", "Xplain::Entity"],
      ["_:p1.1", "#{@rdf_ns}type", "#{@xplain_ns}Type1"],

      [ "#{@xplain_ns}np1.1", "#{@xplain_ns}index", "1"], 
      ["#{@xplain_ns}np1.1", "#{@xplain_ns}has_item", "_:p1.1"],
      ["#{@xplain_ns}np1", "#{@xplain_ns}children", "#{@xplain_ns}np1.1"], 
      
      ["#{@xplain_ns}np2", "#{@xplain_ns}included_in", "#{@xplain_ns}test_id"],
      ["#{@xplain_ns}np2", "#{@dcterms}title", "_:p2"],
      [ "#{@xplain_ns}np2", "#{@xplain_ns}index", "2"],
      ["_:p2", "#{@xplain_ns}item_type", "Xplain::Entity"], 
      ["_:p2", "#{@rdf_ns}type", "#{@xplain_ns}Type2"],
      ["_:p2", "#{@xplain_ns}text", "Text"], 
      ["#{@xplain_ns}np2", "#{@xplain_ns}has_item", "_:p2"]

    ]
    insert = generate_insert_stmt(rs1_triples)

    @sparql_client.update(insert)

    view_profile = Xplain::Visualization::Profile.new(id: "#{@xplain_ns}test_profile")
    view_profile.label_for_type "#{@xplain_ns}Type1", "#{@xplain_ns}item_type"
    view_profile.label_for_type "#{@xplain_ns}Type2", "#{@xplain_ns}index", "#{@xplain_ns}text"
    view_profile.text_for "xplain:index", "Índice"
    view_profile.text_for "xplain:Type1", "Tipo 1"
    view_profile.text_for "xplain:Type2", "Tipo 2"
    
    actual_rs = Xplain::ResultSet.load("#{@xplain_ns}test_id")
    
    actual_rs.nodes.each{|n| n.item.server = @server}
    view_profile.set_view_properties(actual_rs.nodes)
    

    
    p1 = actual_rs.nodes.select{|n| n.item.id == "_:p1"}.first
    p2 = actual_rs.nodes.select{|n| n.item.id == "_:p2"}.first

    assert_equal "Xplain::Entity", p1.item.text
    assert_equal "Text", p2.item.text

    assert_equal "Tipo 1", p1.item.types.first.text
    assert_equal "Tipo 2", p2.item.types.first.text
  end

  def test_load_session_view_profile

    session_triples = [
      ["#{@xplain_ns}test_session", "#{@rdf_ns}type", "#{@xplain_ns}Session"],
      ["#{@xplain_ns}test_session", "#{@dcterms}title", "test session"],
      ["#{@xplain_ns}test_session", "#{@xplain_ns}has_view_profile", "#{@xplain_ns}test_profile"],
    ]
    profile_triples_to_insert = [
      ["#{@xplain_ns}test_profile", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile", "#{@dcterms}title", "test_profile"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://www.w3.org/2000/01/rdf-schema#Resource<=>#{@dcterms}title<=>#{@rdf_ns}label"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}label_for", "#{@dcterms}title<=>Título"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}inverse_label_for", "#{@rdf_ns}type<=>type of"],
    ]

    session_rs_triples = session_triples + profile_triples_to_insert
    sparql_insert = generate_insert_stmt(session_rs_triples)
    
    @sparql_client.update(sparql_insert)
    
    session_found = Xplain::Session.find_by_title("test session").first
    
    assert_false session_found.nil?
    assert_equal "test session", session_found.title
    assert_equal "xplain:test_session", session_found.id

    profile = session_found.view_profile
    assert_false profile.nil?
    assert_equal "test_profile", profile.name
    assert_equal ["#{@dcterms}title", "#{@rdf_ns}label"], profile.labels_by_type_dict["http://www.w3.org/2000/01/rdf-schema#Resource"]
    assert_equal "Título", profile.item_text_dict["#{@dcterms}title"]
    assert_equal "type of", profile.inverse_relation_text_dict["#{@rdf_ns}type"]
    puts profile.to_json()
  end

  def test_save_session_view_profile
    
    current_profile = Xplain::Visualization::Profile.new(id: "#{@xplain_ns}test_profile")
    current_profile.label_for_type "http://www.w3.org/2000/01/rdf-schema#Resource", "dcterms:title"
    current_profile.label_for_type "foaf:Agent", "foaf:name", "foaf:givenName"

    session = Xplain::Session.new(id: "#{@xplain_ns}test_session", view_profile: current_profile, server: @server)
    
    session.save

    expected_triples = [
      ["#{@xplain_ns}test_session", "#{@rdf_ns}type", "#{@xplain_ns}Session"],
      ["#{@xplain_ns}test_session", "#{@xplain_ns}has_view_profile", "#{@xplain_ns}test_profile"],
      ["#{@xplain_ns}test_session", "#{@xplain_ns}server", "default"],
      ["#{@xplain_ns}test_session", "#{@dcterms}title", "test session"],

      ["#{@xplain_ns}test_profile", "#{@rdf_ns}type", "#{@xplain_ns}ViewProfile"],
      ["#{@xplain_ns}test_profile", "#{@dcterms}title", "test profile"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://www.w3.org/2000/01/rdf-schema#Resource<=>#{@dcterms}title"],
      ["#{@xplain_ns}test_profile", "#{@xplain_ns}has_view_type", "http://xmlns.com/foaf/0.1/Agent<=>http://xmlns.com/foaf/0.1/name<=>http://xmlns.com/foaf/0.1/givenName"],
    ]
    actual_triples = get_triples_array("SELECT * WHERE {?s ?p ?o. VALUES ?s {<#{@xplain_ns}test_profile> <#{@xplain_ns}test_session>}}")
    
    assert_equal expected_triples.sort{|t1,t2| (t1[0] + t1[1] + t1[2]) <=> (t2[0] + t2[1] + t2[2])}, actual_triples.sort{|t1,t2| (t1[0] + t1[1] + t1[2]) <=> (t2[0] + t2[1] + t2[2])}
  end
  

end

