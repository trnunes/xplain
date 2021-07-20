require './test/xplain_unit_test'


class ModelTest < XplainUnitTest
  
  def test_empty
    cite = Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite")
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:paper2")])
    assert_true actual_image.empty?
    
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p4")])
    assert_true actual_image.empty?    

    actual_image = cite.restricted_domain(create_nodes [Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7")])
    assert_true actual_image.empty?
        
    cite = Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true)
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7")])
    assert_true actual_image.empty?
  end
  
  def test_restricted_image
    cite = Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite")
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:paper1")])
    
    expected_image = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    
    assert_same_items_set expected_image, actual_image
  end
  
  def test_restricted_domain
    cite = Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite")
    res_dom = cite.restricted_domain(create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")])
    expected_domain = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8")]
    assert_same_items_set expected_domain, res_dom
  end
  
  def test_inverse_restricted_image
    cite = Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true)
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p4")])
    expected_image = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6")]
    assert_same_items_set expected_image, actual_image
  end
  
  def test_inverse_restricted_domain
    cite = Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true)
    res_dom = cite.restricted_domain(create_nodes [Xplain::Entity.new("_:paper1")])
    expected_domain = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    assert_same_items_set expected_domain, res_dom
  end

  def test_path_restricted_image
    path = Xplain::PathRelation.new(server: @papers_server, relations: [Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite"), Xplain::SchemaRelation.new(server: @papers_server, id: "_:author")])
    actual_image = path.restricted_image(create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6")])
    expected_image = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]

    assert_same_items_set expected_image, actual_image
  end

  def test_path_restricted_domain
    path = Xplain::PathRelation.new(server: @papers_server, relations: [Xplain::SchemaRelation.new(server: @papers_server, id: "_:publishedOn"), Xplain::SchemaRelation.new(server: @papers_server, id: "_:releaseYear")])
    actual_image = path.restricted_domain(create_nodes [Xplain::Literal.new("2005", RDF::XSD.string.to_s)])
    expected_image = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p4")]
    assert_same_items_set expected_image, actual_image
  end
  
  def test_inverse_path_restricted_image
    expected_rs = create_nodes [Xplain::Entity.new("_:p7"),Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")]
    path = Xplain::PathRelation.new(server: @papers_server, relations: [Xplain::SchemaRelation.new(server: @papers_server, id: "_:author", inverse: true), Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true)])
    actual_image = path.restricted_image(create_nodes [Xplain::Entity.new("_:a1")])
    assert_same_items_set expected_rs, actual_image
  end
  
  def test_mixed_path_restricted_image    
    path = Xplain::PathRelation.new(server: @papers_server, relations: [Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true), Xplain::SchemaRelation.new(server: @papers_server, id: "_:author")])
    actual_image = path.restricted_image(create_nodes [Xplain::Entity.new("_:p5")])
    assert_same_items_set actual_image, create_nodes([Xplain::Entity.new("_:a2")])
  end

  def test_mixed_path_restricted_domain
    path = Xplain::PathRelation.new(server: @papers_server, relations: [Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true), Xplain::SchemaRelation.new(server: @papers_server, id: "_:author")])
    res_dom = path.restricted_domain(create_nodes [Xplain::Entity.new("_:a1")])
    assert_same_items_set res_dom, create_nodes([Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")])
  end
  ############# TEST COMPUTED RELATION ######################

  def test_empty_computed_relation

    cite = Xplain::ResultSet.new()
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:paper2")])
    assert_equal Set.new(), Set.new(actual_image)
    
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p4")])
    assert_equal Set.new(), Set.new(actual_image)
    

    res_dom = cite.restricted_domain(create_nodes [Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7")])
    assert_equal Set.new(), Set.new(res_dom)
    
    cite = Xplain::ResultSet.new()
    cite = cite.reverse
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7")])
    assert_equal Set.new(), Set.new(actual_image)
    
  end
  
  def test_restricted_image_computed_relation
    paper1 = Xplain::Node.new(item: Xplain::Entity.new("_:paper1"))
    p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    paper1.children = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    p2.children = create_nodes [Xplain::Entity.new("_:p5")]

    cite = Xplain::ResultSet.new(nodes:  [paper1, p2])
    actual_image = cite.restricted_image(create_nodes [Xplain::Entity.new("_:paper1")])
    expected_image = Set.new(create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")])
    assert_same_items_set expected_image, actual_image

  end
  
  def test_restricted_domain_computed_relation
    paper1 = Xplain::Node.new(item: Xplain::Entity.new("_:paper1"))
    p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    paper1.children = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    p2.children = create_nodes [Xplain::Entity.new("_:p5")]
    
    cite = Xplain::ResultSet.new(nodes:  [paper1, p2])
    res_dom = cite.restricted_domain(create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")])
    expected_domain = Set.new(create_nodes [Xplain::Entity.new("_:paper1")])
    assert_same_items_set expected_domain, res_dom
  end  
  
  def test_group_by_computed_relation
    paper1 = Xplain::Node.new(item: Xplain::Entity.new("_:paper1"))
    p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    paper1.children = create_nodes [Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    p2.children = create_nodes [Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5")]
    
    expected_groups = create_nodes [Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4"), Xplain::Entity.new("_:p5")]
    p3_children = [p2, paper1]
    p4_children = [paper1]
    p5_children = [p2]
    
    actual_groups = Xplain::ResultSet.new(nodes:  [paper1, p2]).group_by_image()
    assert_same_items_set expected_groups, actual_groups
    
    actual_p3_children = actual_groups.select{|n| n.item.id == "_:p3"}[0].children
    actual_p4_children = actual_groups.select{|n| n.item.id == "_:p4"}[0].children
    actual_p5_children = actual_groups.select{|n| n.item.id == "_:p5"}[0].children
    
    assert_same_items_set  p3_children, actual_p3_children
    assert_same_items_set  p4_children, actual_p4_children
    assert_same_items_set  p5_children, actual_p5_children
    
  end
  
  def test_entity_namespace
    Xplain::Namespace.new("xplain", "http://xplain/")
    paper1 = Xplain::Entity.new("_:paper1")
    expected_results = create_nodes [Xplain::Entity.new('_:p2'), Xplain::Entity.new('_:p3'), Xplain::Entity.new('_:p4')]
    assert_same_items_set expected_results, paper1.xplain__cites.nodes
  end
  
  def test_dsl_inverse_relation
    Xplain::Namespace.new("xplain", "http://xplain/")
    paper1 = Xplain::Entity.new("_:p2")
    expected_results = create_nodes [Xplain::Entity.new('_:paper1')]
    assert_same_items_set expected_results, paper1.xplain__cites(:inverse).nodes
  end
  
  def test_relations_image
    Xplain::Namespace.new("xplain", "http://xplain/")
    expected_results = create_nodes [
        Xplain::SchemaRelation.new(id: "_:publishedOn"),
        Xplain::SchemaRelation.new(id: "_:author"),
        Xplain::SchemaRelation.new(id: "_:cite"), 
        Xplain::SchemaRelation.new(id: "_:submittedTo"), 
        Xplain::SchemaRelation.new(id: "xplain:cites"),
        Xplain::SchemaRelation.new(id: "rdf:type"),
        Xplain::SchemaRelation.new(id: "_:keywords"),
        Xplain::SchemaRelation.new(id: "_:releaseYear"),
        Xplain::SchemaRelation.new(id: "_:publicationYear"),
        Xplain::SchemaRelation.new(id: "_:relevance"),
        Xplain::SchemaRelation.new(id: "rdf:label"),
        Xplain::SchemaRelation.new(id: "_:alternative_label_property"),
             
      ]
      
      relations = Xplain::SchemaRelation.new(server: @papers_server, id: "relations")
      assert_same_items_set expected_results, relations.image
  
  end
  
  def test_relations_restricted_image
    expected_results = create_nodes [
        Xplain::SchemaRelation.new(id: "_:author"), 
        Xplain::SchemaRelation.new(id: "_:keywords"),
        Xplain::SchemaRelation.new(id: "_:cite", inverse: true),
        Xplain::SchemaRelation.new(id: "rdf:label"),
    ]      
    relations = Xplain::SchemaRelation.new(server: @papers_server, id: "relations")
    actual_results = relations.restricted_image(create_nodes [Xplain::Entity.new("_:p5")])
    assert_same_items_set expected_results, actual_results
    
  end
  
  def test_has_type_image
    expected_results = Xplain::ResultSet.new nodes: create_nodes([
        Xplain::Type.new("_:type1"),
        Xplain::Type.new("_:type2")         
      ])
      
    has_type = Xplain::SchemaRelation.new(server: @papers_server, id: "has_type")
    assert_same_result_set_no_title expected_results, has_type.image  
  end
  
  def test_has_type_restricted_image
    expected_results = Xplain::ResultSet.new nodes: create_nodes([
        Xplain::Type.new("_:type1")        
    ])
      
    has_type = Xplain::SchemaRelation.new(server: @papers_server, id: "has_type")
    actual_results = has_type.restricted_image(create_nodes [Xplain::Entity.new("_:p9")])
    assert_same_result_set_no_title expected_results, actual_results
    
  end
  
  def test_relations_restricted_domain
    expected_results = Xplain::ResultSet.new nodes: create_nodes([      
      Xplain::Entity.new("_:paper1"),
      Xplain::Entity.new("_:p2"),
      Xplain::Entity.new("_:p3"),
      Xplain::Entity.new("_:p6"),
      Xplain::Entity.new("_:p5"),
      Xplain::Entity.new("_:p20")      
     ])
      
    relations = Xplain::SchemaRelation.new(server: @papers_server, id: "relations")
    actual_results = relations.restricted_domain(create_nodes [
      Xplain::SchemaRelation.new(id: "_:author")        
    ])
    assert_same_result_set_no_title expected_results, actual_results
  end
  
  def test_has_type_restricted_domain
    expected_results = create_nodes [
        Xplain::Entity.new("_:p9")
    ]
    expected_rs = Xplain::ResultSet.new nodes: expected_results
    has_type = Xplain::SchemaRelation.new(server: @papers_server, id: "has_type")
    actual_results = has_type.restricted_domain(create_nodes [Xplain::Entity.new("_:type1")])
    assert_same_result_set_no_title expected_rs, actual_results
  end
  
  def test_result_set_uniq_items
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2")), Xplain::Node.new(item: Xplain::Entity.new("_:p2"))])
    assert_equal input.size, 3
    expected_result_set = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2"))])
    assert_same_result_set_no_title expected_result_set, input.uniq.execute
  end
  
  def test_result_set_sort
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:a")), Xplain::Node.new(item: Xplain::Entity.new("_:c")), Xplain::Node.new(item: Xplain::Entity.new("_:b"))])
    expected_nodes_array = [Xplain::Node.new(item: Xplain::Entity.new("_:a")), Xplain::Node.new(item: Xplain::Entity.new("_:b")), Xplain::Node.new(item: Xplain::Entity.new("_:c"))]
    assert_same_items input.sort_asc.nodes, expected_nodes_array
  end
  
  def test_result_set_sort_by_text
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:a", "b")), Xplain::Node.new(item: Xplain::Entity.new("_:c", "a")), Xplain::Node.new(item: Xplain::Entity.new("_:b", "c"))])
    expected_nodes_array = [Xplain::Node.new(item: Xplain::Entity.new("_:c")), Xplain::Node.new(item: Xplain::Entity.new("_:a")), Xplain::Node.new(item: Xplain::Entity.new("_:b"))]
    assert_same_items input.sort_asc.nodes, expected_nodes_array
  end
  
  def test_result_set_sort_literals_string
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Literal.new("b")), Xplain::Node.new(item: Xplain::Literal.new("a")), Xplain::Node.new(item: Xplain::Literal.new("c"))])
    expected_nodes_array = [Xplain::Node.new(item: Xplain::Literal.new("a")), Xplain::Node.new(item: Xplain::Literal.new("b")), Xplain::Node.new(item: Xplain::Literal.new("c"))]
    assert_same_items input.sort_asc.nodes, expected_nodes_array
  end
  
  def test_result_set_sort_literals_string_numeric
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Literal.new("12")), Xplain::Node.new(item: Xplain::Literal.new("112")), Xplain::Node.new(item: Xplain::Literal.new("3"))])
    expected_nodes_array = [Xplain::Node.new(item: Xplain::Literal.new("3")), Xplain::Node.new(item: Xplain::Literal.new("12")), Xplain::Node.new(item: Xplain::Literal.new("112"))]
    assert_same_items input.sort_asc.nodes, expected_nodes_array
  end
  
  def test_result_set_sort_literals_numeric
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Literal.new(12)), Xplain::Node.new(item: Xplain::Literal.new(112)), Xplain::Node.new(item: Xplain::Literal.new(3))])
    expected_nodes_array = [Xplain::Node.new(item: Xplain::Literal.new(112)), Xplain::Node.new(item: Xplain::Literal.new(12)), Xplain::Node.new(item: Xplain::Literal.new(3))]
    assert_same_items expected_nodes_array, input.sort.nodes
  end
end