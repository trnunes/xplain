require './exceptions/invalid_input_exception'
require './test/xplain_unit_test'
require './operations/group_aux/grouping_relation'
Dir['./operations/group_aux/*.rb'].each{|f| require f}


class Xplain::GroupTest < XplainUnitTest

  def test_group_by_empty_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    begin
      rs = Xplain::Group.new(inputs: input){by_image nil}.execute
      assert false, rs.inspect
    rescue MissingRelationException => e
      assert true, e.to_s
      return
    end
    assert false
  end
    
  def test_group_by_empty_input_set
    root = Xplain::ResultSet.new(nodes:  [])

    rs = Xplain::Group.new(inputs: root).execute
    
    assert_true rs.children.empty?, rs.inspect
  end
  
  def test_group_by_single_relation
    a1 = Xplain::Node.new(item: Xplain::Entity.new("_:a1"))
    a1.children = create_nodes [Xplain::Entity.new("_:p2"),Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:paper1")]
    
    a2 = Xplain::Node.new(item: Xplain::Entity.new("_:a2"))
    a2.children = create_nodes [Xplain::Entity.new("_:p3"),Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")]
    
    expected_rs = Xplain::ResultSet.new(id: "rs", nodes:  [a1, a2])
    
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"),Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6") ]
    input_rs = Xplain::ResultSet.new(id: "rs", nodes:  input_nodes)
 
    actual_rs = Xplain::Group.new(inputs:input_rs, grouping_relation: GroupAux::ByImage.new(Xplain::SchemaRelation.new(id: "_:author"))).execute
    assert_same_result_set_no_title expected_rs, actual_rs
  end
  
  def test_group_by_inverse_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:k1"), Xplain::Entity.new("_:k2"), Xplain::Entity.new("_:k3")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    keywords_relation = Xplain::SchemaRelation.new(id: "_:keywords")
    actual_rs = Xplain::Group.new(inputs: input, grouping_relation: GroupAux::ByImage.new(Xplain::SchemaRelation.new(id: "_:keywords", inverse: true))).execute

    p1,p2,p3,p5 = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5")]
    expected_rs = Xplain::ResultSet.new nodes: [p1,p2,p3,p5]
    
    p1.children = create_nodes [Xplain::Entity.new("_:k1"), Xplain::Entity.new("_:k2"), Xplain::Entity.new("_:k3")]
    p2.children = create_nodes [Xplain::Entity.new("_:k3")]
    p3.children = create_nodes [Xplain::Entity.new("_:k2")]
    p5.children = create_nodes [Xplain::Entity.new("_:k1")]
    
    assert_same_result_set_no_title actual_rs, expected_rs
  end
  
  def test_group_by_path_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:publishedOn"), Xplain::SchemaRelation.new(id: "_:releaseYear")])
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    actual_rs = Xplain::Group.new(inputs: input, grouping_relation: GroupAux::ByImage.new(path)).execute

    expected_rs = create_nodes [Xplain::Literal.new(2005), Xplain::Literal.new(2010)]
    
    l2005 = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p4")]
    l2010 = create_nodes [Xplain::Entity.new("_:p3")]
  end
  
  def test_group_by_inverse_path_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:author", inverse: true), Xplain::SchemaRelation.new(id: "_:cite", inverse: true)])
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    

    actual_rs = Xplain::Group.new(inputs: input, grouping_relation: GroupAux::ByImage.new(path)).execute

    p1,p6,p7,p8,p9,p10 = create_nodes [Xplain::Entity.new("_:p7"),Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")]
    expected_rs = Xplain::ResultSet.new nodes: [p1,p6,p7,p8,p9,p10] 
    p1.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p6.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p7.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p8.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p9.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p10.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    
    assert_same_result_set_no_title actual_rs, expected_rs
  end
  
  def test_group_by_mixed_path
    input_nodes = create_nodes [Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:cite", inverse: true), Xplain::SchemaRelation.new(id: "_:author")])
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    

    actual_rs = Xplain::Group.new(inputs: input, grouping_relation: GroupAux::ByImage.new(path)).execute
    
    a1,a2 = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    expected_rs = Xplain::ResultSet.new nodes: [a1,a2]
    
    a1.children = create_nodes ["_:p3", "_:p4"].map{|id| Xplain::Entity.new id}
    a2.children = create_nodes ["_:p5", "_:p3", "_:p4"].map{|id| Xplain::Entity.new id}
    
    assert_same_result_set_no_title actual_rs, expected_rs
  end
  
  def test_group_two_levels
    
    input_nodes = create_nodes [
      Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"),
      Xplain::Entity.new("_:p4"), Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6"),
      Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"),
    ]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    

     expr = Xplain::Group.new(inputs: 
      Xplain::Group.new(inputs: input, grouping_relation: GroupAux::ByImage.new(Xplain::SchemaRelation.new(id: "_:author"))), 
      grouping_relation: GroupAux::ByImage.new(Xplain::SchemaRelation.new(id: "_:publicationYear"))
    )
    profile = Xplain::Visualization::Profile.new(id: "test")
    @papers_session.view_profile = profile
    actual_rs = @papers_session.execute(expr)
    
    a1,a2 = create_nodes([Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")])
    expected_rs = Xplain::ResultSet.new nodes: [a1,a2]

    a1.children = create_nodes([Xplain::Literal.new(2000)])
    a2.children = create_nodes([Xplain::Literal.new(1998)])
    a1.children.first.children = create_nodes([Xplain::Entity.new("_:p2")]) 
    a2.children.first.children = create_nodes([Xplain::Entity.new("_:p3")])
    assert_same_result_set_no_title actual_rs, expected_rs
    
  end
  
  def test_dsl_group_by_single_relation
    
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"),Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6") ]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    author_relation = Xplain::SchemaRelation.new(id: "_:author", inverse: true)
    
    actual_rs = input.group{by_image{relation "_:author"}}.execute
    

    a1,a2 = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    expected_rs = Xplain::ResultSet.new nodes: [a1, a2]
    a1.children = create_nodes [Xplain::Entity.new("_:p2"),Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:paper1")]
    a2.children = create_nodes [Xplain::Entity.new("_:p3"),Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")]
    assert_same_result_set_no_title actual_rs, expected_rs
  end
  
  def test_dsl_group_by_inverse_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:k1"), Xplain::Entity.new("_:k2"), Xplain::Entity.new("_:k3")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
        
    keywords_relation = Xplain::SchemaRelation.new(id: "_:keywords")

    actual_rs = input.group{ by_image{ relation inverse("_:keywords") }}.execute
    p1, p2, p3, p5 = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5")]
    p1.children = create_nodes [Xplain::Entity.new("_:k1"), Xplain::Entity.new("_:k2"), Xplain::Entity.new("_:k3")]
    p2.children = create_nodes [Xplain::Entity.new("_:k3")]
    p3.children = create_nodes [Xplain::Entity.new("_:k2")]
    p5.children = create_nodes [Xplain::Entity.new("_:k1")]
    expected_rs = Xplain::ResultSet.new nodes: [p1,p2,p3,p5]
    
    assert_same_result_set_no_title actual_rs, expected_rs
  end
  
  def test_dsl_group_by_path_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:publishedOn"), Xplain::SchemaRelation.new(id: "_:releaseYear")])
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    actual_rs = input.group{ by_image{relation "_:publishedOn", "_:releaseYear"}}.execute

    
    l2005, l2010 = create_nodes [Xplain::Literal.new(2005), Xplain::Literal.new(2010)]
    expected_rs = Xplain::ResultSet.new nodes: [l2005, l2010]
    l2005.children = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p4")]
    l2010.children = create_nodes [Xplain::Entity.new("_:p3")]
    
    assert_same_result_set_no_title actual_rs, expected_rs
  end
  
  def test_dsl_group_by_inverse_path_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:author", inverse: true), Xplain::SchemaRelation.new(id: "_:cite", inverse: true)])
    input = Xplain::ResultSet.new(nodes:  input_nodes)

    actual_rs = input.group{ by_image{relation inverse("_:author"), inverse("_:cite")}}.execute

    p7,p8,p9,p10,p6,p1 = create_nodes [Xplain::Entity.new("_:p7"),Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")]
    expected_rs = Xplain::ResultSet.new nodes: [p7,p8,p9,p10,p6,p1]
    p1.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p6.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p7.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p8.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p9.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    p10.children = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    
    assert_same_result_set_no_title actual_rs, expected_rs

    
  end
end