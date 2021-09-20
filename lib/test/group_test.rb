require './exceptions/invalid_input_exception'
require './test/xplain_unit_test'

Dir['./operations/group_aux/*.rb'].each{|f| require f}


class Xplain::GroupTest < XplainUnitTest

  def test_group_by_single_relation
    a1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1"))
    a1.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p5"),
      Xplain::Entity.new(server: @papers_server, id: "_:paper1")
    ]
    
    a2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a2"))
    a2.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p5"),
      Xplain::Entity.new(server: @papers_server, id: "_:p6"),
      Xplain::Entity.new(server: @papers_server, id: "_:paper1")
    ]
    
    expected_rs = [a1, a2]
    
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:paper1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p5"),
      Xplain::Entity.new(server: @papers_server, id: "_:p6")
    ]
    relation = Xplain::SchemaRelation.new(server: @papers_server, id: "_:author")
    aux_function = GroupAux::ByImage.new(relation: relation)
    actual_rs = Xplain::Group.new.get_results(input_nodes:input_nodes, function: aux_function)
    # binding.pry
    assert_same_items_set expected_rs, actual_rs
  end
  
  def test_group_by_inverse_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:k1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:k2"), 
      Xplain::Entity.new(server: @papers_server, id: "_:k3")
    ]
    
    keywords_relation = Xplain::SchemaRelation.new(server: @papers_server, id: "_:keywords")
    relation = Xplain::SchemaRelation.new(server: @papers_server, id: "_:keywords", inverse: true)
    aux_function = GroupAux::ByImage.new(relation: relation)
    actual_rs = Xplain::Group.new.get_results(input_nodes: input_nodes, function: aux_function)

    p1,p2,p3,p5 = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:paper1"),
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p5")
    ]

    expected_rs = Xplain::ResultSet.new nodes: [p1,p2,p3,p5]
    
    p1.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:k1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:k2"),
      Xplain::Entity.new(server: @papers_server, id: "_:k3")
    ]
    p2.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:k3")
    ]
    
    p3.children = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:k2")]
    
    p5.children = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:k1")]
    
    assert_same_items_set actual_rs, expected_rs
  end
  # 
  def test_group_by_path_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p4")
    ]
    path = Xplain::PathRelation.new(relations: [
      Xplain::SchemaRelation.new(server: @papers_server, id: "_:publishedOn"), 
      Xplain::SchemaRelation.new(server: @papers_server, id: "_:releaseYear")
    ])
    aux_function = GroupAux::ByImage.new(relation: path)
    actual_rs = Xplain::Group.new.get_results(input_nodes: input_nodes, function: aux_function)

    expected_rs = create_nodes [
      Xplain::Literal.new(value: 2005), 
      Xplain::Literal.new(value: 2010)
    ]
    
    l2005 = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p4")
    ]
    l2010 = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:p3")]
    expected_rs[0].children = l2005
    expected_rs[1].children = l2010
    assert_same_items_set expected_rs, actual_rs
  end
  # 
  def test_group_by_inverse_path_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:a1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ]
    
    path = Xplain::PathRelation.new(relations: [
      Xplain::SchemaRelation.new(server: @papers_server, id: "_:author", inverse: true), 
      Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true)
    ])
    aux_function = GroupAux::ByImage.new(relation: path)
    
    actual_rs = Xplain::Group.new.get_results(input_nodes: input_nodes, function: aux_function)
    
    p1,p6,p7,p8,p9,p10 = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p7"),
      Xplain::Entity.new(server: @papers_server, id: "_:p8"),
      Xplain::Entity.new(server: @papers_server, id: "_:p9"),
      Xplain::Entity.new(server: @papers_server, id: "_:p10"),
      Xplain::Entity.new(server: @papers_server, id: "_:p6"), 
      Xplain::Entity.new(server: @papers_server, id: "_:paper1")
    ]
    
    expected_rs = [p1,p6,p7,p8,p9,p10]

    p1.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:a1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ]
    p6.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:a1"),
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ]
    p7.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:a1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ]
    p8.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:a1"),
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ]
    p9.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:a1"),
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ]
    p10.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:a1"),
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ]
    
    assert_same_items_set actual_rs, expected_rs
  end
  
  def test_group_by_mixed_path
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p5"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p4")
    ]
    
    path = Xplain::PathRelation.new(relations: [
      Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true), 
      Xplain::SchemaRelation.new(server: @papers_server, id: "_:author")
    ])
    aux_function = GroupAux::ByImage.new(relation: path)
    actual_rs = Xplain::Group.new.get_results(input_nodes: input_nodes, function: aux_function)
    
    a1,a2 = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:a1"), Xplain::Entity.new(server: @papers_server, id: "_:a2")]
    expected_rs = [a1,a2]
    
    a1.children = create_nodes ["_:p3", "_:p4"].map{|id| Xplain::Entity.new id}
    a2.children = create_nodes ["_:p5", "_:p3", "_:p4"].map{|id| Xplain::Entity.new id}
    
    assert_same_items_set actual_rs, expected_rs
  end
  # 
  def test_group_two_levels
    
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p4"), Xplain::Entity.new(server: @papers_server, id: "_:p5"), Xplain::Entity.new(server: @papers_server, id: "_:p6"),
      Xplain::Entity.new(server: @papers_server, id: "_:p7"), Xplain::Entity.new(server: @papers_server, id: "_:p8"), Xplain::Entity.new(server: @papers_server, id: "_:p9"),
    ]
    aux_function = GroupAux::ByImage.new(relation: Xplain::SchemaRelation.new(server: @papers_server, id: "_:author"))
    
    rs = Xplain::Group.new.get_results(input_nodes: input_nodes, function: aux_function)
    rs.each {|n| n.item.server = @papers_server}

    actual_rs = Xplain::Group.new.get_results(
      input_nodes: rs, 
      function: GroupAux::ByImage.new(relation: Xplain::SchemaRelation.new(server: @papers_server, id: "_:publicationYear"))
    )
    
    a1,a2 = create_nodes([
      Xplain::Entity.new(server: @papers_server, id: "_:a1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:a2")
    ])
    
    expected_rs = [a1,a2]

    a1.children = create_nodes([Xplain::Literal.new(value: 2000)])
    a2.children = create_nodes([Xplain::Literal.new(value: 1998)])
    a1.children.first.children = create_nodes([Xplain::Entity.new(server: @papers_server, id: "_:p2")]) 
    a2.children.first.children = create_nodes([Xplain::Entity.new(server: @papers_server, id: "_:p3")])
    assert_same_items_set expected_rs, actual_rs
    
  end
  # 
end