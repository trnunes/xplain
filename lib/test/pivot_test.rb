require './test/xplain_unit_test'


class Xplain::PivotTest < XplainUnitTest

  def test_empty_input_set
    
    input_nodes = []
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    actual_results = Xplain::Pivot.new(inputs: root,  relation: Xplain::SchemaRelation.new(id: "_:r1")).execute()
    assert_true actual_results.children.empty?
  end
  
  def test_empty_relation
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1")),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    begin
      actual_results = Xplain::Pivot.new(inputs: root).execute()
      assert false
    rescue MissingRelationException => e
      assert true
      return
    end
    assert false
    
  end
  
  def test_empty_output
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:notexist1")),
      Xplain::Node.new(item: Xplain::Entity.new("_:notexist2"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)

    actual_results = Xplain::Pivot.new(inputs: root,  relation: Xplain::SchemaRelation.new(id:"_:r1")).execute()
    assert_true actual_results.children.empty?
  end
  
  def test_pivot_single_relation
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1")),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new("_:o1"), Xplain::Entity.new("_:o2")])

    actual_results = Xplain::Pivot.new(inputs: root, server: @server, relation: Xplain::SchemaRelation.new(id:"_:r1", server: @server)).execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
    
  end
  
  def test_pivot_single_relation_grouped_by_domain
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1")),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expec_p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    expec_p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    expec_p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:o1")), Xplain::Node.new(item: Xplain::Entity.new("_:o2"))]
    expec_p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:o2"))]
    
    expected_rs = Xplain::ResultSet.new(nodes:  [expec_p1, expec_p2])

    actual_results = Xplain::Pivot.new(inputs: root, server: @server, relation: Xplain::SchemaRelation.new(id:"_:r1", server: @server), group_by_domain: true).execute()
    actual_results.title = expected_rs.title
    assert_same_result_set actual_results, expected_rs
  end
  
  def test_pivot_single_relation_inverse
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new("_:p3"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8")])

    actual_results = Xplain::Pivot.new(inputs: root,  relation: Xplain::SchemaRelation.new(id:"_:cite", inverse: true)).execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end

  def test_pivot_relation_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:paper1")),
      Xplain::Node.new(item: Xplain::Entity.new("_:p6"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")])
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:cite"), Xplain::SchemaRelation.new(id: "_:author")])
    actual_results = Xplain::Pivot.new(inputs: root,  relation: path).execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end
  
  
  def test_pivot_backward_relation_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:a1"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:author", inverse: true), Xplain::SchemaRelation.new(id: "_:cite", inverse: true)])
    expected_results = Set.new([Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10")])

    actual_results = Xplain::Pivot.new(inputs: root,  relation: path).execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end
  
  def test_pivot_backward_relation_path_dsl
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:a1"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10")])

    actual_results = root.pivot{relation inverse("_:author"), inverse("_:cite")}.execute
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end
    
  def test_pivot_forward_backward_relation_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:journal1"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new("_:a1")])
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:publishedOn", inverse: true), Xplain::SchemaRelation.new(id: "_:author")])
    actual_results = Xplain::Pivot.new(inputs: root,  relation: path).execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end
  
  def test_pivot_direct_computed_relation
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i1p3 = Xplain::Node.new(item: Xplain::Entity.new("_:p3"))
    i1p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"))]
    i1p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2.2"))]
    i1p3.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p3.1"))]
    computed_relation = Xplain::ResultSet.new(nodes:  [i1p1, i1p2, i1p3])
    
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1"))])
    
    expected_rs = Xplain::ResultSet.new(nodes:  i1p1.children)
    actual = input.pivot{relation computed_relation}.execute
    actual.title = expected_rs.title
    assert_same_result_set expected_rs, actual 

    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2"))])
    
    expected_rs = Xplain::ResultSet.new(nodes:  i1p1.children + i1p2.children)
    actual = input.pivot{relation computed_relation}.execute
    actual.title = expected_rs.title
    assert_same_result_set expected_rs, actual 

  end
  
  def test_pivot_inverse_computed_relation
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i1p3 = Xplain::Node.new(item: Xplain::Entity.new("_:p3"))
    i1p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"))]
    i1p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2.2"))]
    i1p3.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p3.1"))]
    computed_relation = Xplain::ResultSet.new(nodes:  [i1p1, i1p2, i1p3])
    
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"))])
    
    expected_rs = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1"))])
    
    actual = input.pivot{relation inverse: computed_relation}.execute
    actual.title = expected_rs.title
    assert_same_result_set expected_rs, actual 
    
    input = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p3.1"))])
    
    expected_rs = Xplain::ResultSet.new(nodes:  [Xplain::Node.new(item: Xplain::Entity.new("_:p1")), Xplain::Node.new(item: Xplain::Entity.new("_:p3"))])
    actual = input.pivot{relation inverse: computed_relation}.execute
    actual.title = expected_rs.title
    assert_same_result_set expected_rs, actual 
  end
 
end