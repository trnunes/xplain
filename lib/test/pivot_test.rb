require './test/xplain_unit_test'


class Xplain::PivotTest < XplainUnitTest

  def test_empty_input_set
    
    input_nodes = []
    
    relation = Xplain::SchemaRelation.new(id: "_:r1")

    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes,  relation: relation)
    assert_true actual_results.empty?
  end
  
  def test_empty_relation
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p2"))
    ]
    
    begin
      actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes)
      assert false
    rescue MissingRelationException => e
      assert true
      return
    end
    assert false
    
  end
  
  def test_empty_output
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:notexist1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:notexist2"))
    ]

    relation = Xplain::SchemaRelation.new(id:"_:r1")
    
    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes,  relation: relation)
    
  end
  
  def test_pivot_single_relation
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p2"))
    ]
    
    expected_results = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:o1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:o2"))
    ]

    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes, server: @server, relation: Xplain::SchemaRelation.new(id:"_:r1", server: @server))
    assert_false actual_results.empty?
    assert_same_items_set expected_results, actual_results
    
  end
  
  def test_pivot_single_relation_grouped_by_domain
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p2"))
    ]
    
    expec_p1 = Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p1"))
    expec_p2 = Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:p2"))
    expec_p1.children = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:o1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:o2"))
    ]
    expec_p2.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @server, id: "_:o2"))]
    
    expected_rs = [expec_p1, expec_p2]
    relation = Xplain::SchemaRelation.new(id:"_:r1")

    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes, relation: relation, group_by_domain: true)
    
    assert_same_items_set actual_results, expected_rs
  end
  
  def test_pivot_single_relation_inverse
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    ]
    
    expected_results = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p7")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p8"))
    ]

    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes,  relation: Xplain::SchemaRelation.new(id:"_:cite", inverse: true))
    assert_false actual_results.empty?
    assert_same_items_set expected_results, actual_results
  end

  def test_pivot_relation_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6"))
    ]
    
    expected_results = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a2"))
    ]
    
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:cite"), Xplain::SchemaRelation.new(id: "_:author")])
    
    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes,  relation: path)
    assert_false actual_results.empty?
    assert_same_items_set expected_results, actual_results
  end
  
  
  def test_pivot_backward_relation_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1"))
    ]
    
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:author", inverse: true), Xplain::SchemaRelation.new(id: "_:cite", inverse: true)])
    expected_results = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p7")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p8")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p9")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p10"))
    ]

    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes,  relation: path)
    assert_false actual_results.empty?
    assert_same_items_set expected_results, actual_results
  end
  
  # def test_pivot_backward_relation_path_dsl
    # input_nodes = [
      # Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1"))
    # ]
    # 
    # expected_results = [
      # Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")), 
      # Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6")), 
      # Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p7")), 
      # Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p8")), 
      # Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p9")), 
      # Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p10"))
    # ]
# 
    # actual_results = root.pivot{relation inverse("_:author"), inverse("_:cite")}.execute
    # assert_false actual_results.empty?
    # assert_same_items_set expected_results, actual_results
  # end
    
  def test_pivot_forward_backward_relation_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1"))
    ]
    
    expected_results = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1"))]

    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:publishedOn", inverse: true), Xplain::SchemaRelation.new(id: "_:author")])
    
    actual_results = Xplain::Pivot.new.get_results(input_nodes: input_nodes,  relation: path)
    assert_false actual_results.empty?
    assert_same_items_set expected_results, actual_results
  end
  
  def test_pivot_direct_computed_relation
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    i1p3 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    i1p1.children = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.2"))
    ]
    i1p2.children = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2.1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2.2"))
    ]
    i1p3.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3.1"))]
    
    computed_relation = Xplain::ResultSet.new(nodes:  [i1p1, i1p2, i1p3])
    
    input = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1"))]
    
    expected_rs =i1p1.children
    # binding.pry    
    actual = Xplain::Pivot.new.get_results(relation: computed_relation, input_nodes: input)
    
    assert_same_items expected_rs, actual 

    input = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    ]
    
    expected_rs = i1p1.children + i1p2.children
    actual = Xplain::Pivot.new.get_results(relation: computed_relation, input_nodes: input)
    assert_same_items expected_rs, actual 

  end
  
  def test_pivot_inverse_computed_relation
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    i1p3 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    i1p1.children = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.2"))
    ]
    i1p2.children = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2.1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2.2"))
    ]
    i1p3.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3.1"))]
    
    computed_relation = Xplain::ResultSet.new(nodes: [i1p1, i1p2, i1p3])
    
    input = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.2"))]
    
    expected_rs = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1"))]
    
    actual = Xplain::Pivot.new.get_results(input_nodes: input, relation: computed_relation.reverse())
    
    assert_same_items_set expected_rs, actual 
    
    input = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1.1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3.1"))
    ]
    
    expected_rs = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p1")), 
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    ]
    
    

    actual = Xplain::Pivot.new.get_results(input_nodes: input, relation: computed_relation.reverse())
    
    assert_same_items_set expected_rs, actual 
  end
 
end