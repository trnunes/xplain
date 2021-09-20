require './test/xplain_unit_test'
Dir['./operations/xmap_aux/*.rb'].each{|f| require f}
Dir['./operations/aggregate_aux/*.rb'].each{|f| require f}
class MapTest < XplainUnitTest

  def test_map_by_empty_input_set
    

    rs = Xplain::Aggregate.new.get_results(input_nodes: [], function: AggregateAux::Sum.new(relation: Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite")))

    assert_true rs.empty?, rs.inspect
  end

  def test_sum_by_single_relation_0
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p5"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p6"),
      Xplain::Entity.new(server: @papers_server, id: "_:p7")
    ]
    
    rs = Xplain::Aggregate.new.get_results(input_nodes: input_nodes, function: AggregateAux::Sum.new(relation: Xplain::SchemaRelation.new(server: @papers_server, id: "_:relevance")))
    
    assert_same_items_set rs, input_nodes
    assert_true rs.map{|n| n.children}.flatten.empty?
  end
  
  
  def test_sum_single_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p4")
    ]
    
    
    rs = Xplain::Sum.new.get_results(input_nodes: input_nodes, relation: Xplain::SchemaRelation.new(id: "_:relevance"))
    # binding.pry
    assert_equal 3, rs.size
    assert_same_items_set input_nodes, rs
    
    p2 = rs.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.select{|node| node.item.id == "_:p3"}[0]
    p4 = rs.select{|node| node.item.id == "_:p4"}[0]
    
    expected_rs_children = create_nodes [
      Xplain::Literal.new(value: 30.0),
      Xplain::Literal.new(value: 24.0),
      Xplain::Literal.new(value: 20.0)
    ]
    
    actual_rs_children = [p2.children[0], p3.children[0], p4.children[0]]
    
    assert_same_items_set expected_rs_children, actual_rs_children
  end
  
  def test_count_by_single_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p6"),
      Xplain::Entity.new(server: @papers_server, id: "_:paper1")
    ]
    
    rs = Xplain::Count.new.get_results(input_nodes: input_nodes, relation: Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite"))
    
    assert_equal 3, rs.size
    assert_same_items_set input_nodes, rs
    
    p2 = rs.select{|node| node.item.id == "_:p2"}[0]
    p6 = rs.select{|node| node.item.id == "_:p6"}[0]
    paper1 = rs.select{|node| node.item.id == "_:paper1"}[0]
    
    expected_rs_children = create_nodes [
      Xplain::Literal.new(value: 0),
      Xplain::Literal.new(value: 3),
      Xplain::Literal.new(value: 3)
    ]
    actual_rs_children = [p2.children[0], p6.children[0], paper1.children[0]]
    
    assert_same_items expected_rs_children, actual_rs_children
  end

  def test_count_by_inverse_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:paper1"),
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3")
    ]
    
    rs = Xplain::Count.new.get_results(input_nodes: input_nodes, relation: Xplain::SchemaRelation.new(server: @papers_server, id: "_:cite", inverse: true))
    
    assert_equal 3, rs.size
    assert_same_items_set input_nodes, rs
    
    paper1 = rs.select{|node| node.item.id == "_:paper1"}[0]
    p2 = rs.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.select{|node| node.item.id == "_:p3"}[0]
    
    expected_rs_children = create_nodes [
      Xplain::Literal.new(value: 0), 
      Xplain::Literal.new(value: 2), 
      Xplain::Literal.new(value: 4)
    ]

    actual_rs_children = [paper1.children[0], p2.children[0], p3.children[0]]
    
    assert_same_items expected_rs_children, actual_rs_children
  end
  
  def test_average
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p4")
    ]
    
    rs = Xplain::Avg.new.get_results(input_nodes: input_nodes, relation: Xplain::SchemaRelation.new(id: "_:relevance"))
    
    assert_equal 3, rs.size
    assert_same_items_set input_nodes, rs
    
    p2 = rs.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.select{|node| node.item.id == "_:p3"}[0]
    p4 = rs.select{|node| node.item.id == "_:p4"}[0]
    
    expected_rs_children = create_nodes [
      Xplain::Literal.new(value: 15.0),
      Xplain::Literal.new(value: 12.0),
      Xplain::Literal.new(value: 10.0)
    ]
    
    actual_rs_children = [p2.children[0], p3.children[0], p4.children[0]]

    assert_same_items expected_rs_children, actual_rs_children
  end
  
  def test_count_computed_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p4")
    ]
    
    rs = Xplain::Count.new.get_results(input_nodes: input_nodes)
    
    assert_equal 1, rs.size
    assert_same_items_set create_nodes([Xplain::Literal.new(value: 3)]), rs
    
  end
  
  def test_count_computed_relation_level_2
    
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p3"),
      Xplain::Entity.new(server: @papers_server, id: "_:p4")
    ]
    
    input_nodes.first.children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p2.1"),
      Xplain::Entity.new(server: @papers_server, id: "_:p2.2"),
      Xplain::Entity.new(server: @papers_server, id: "_:p2.3")
    ]
    
    input_nodes[1].children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p3.1"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p3.2")
    ]
    
    input_nodes[2].children = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:p4.1")
    ]
    
    relation = Xplain::ResultSet.new(nodes: input_nodes)
    rs = Xplain::Count.new.get_results(input_nodes: input_nodes, level: 1, relation: relation)
    assert_equal 3, rs.size

    p2 = rs.select{|node| node.item.id == "_:p2"}.first
    p3 = rs.select{|node| node.item.id == "_:p3"}.first
    p4 = rs.select{|node| node.item.id == "_:p4"}.first
    
    assert_same_items create_nodes([Xplain::Literal.new(value: 3)]), p2.children
    
    assert_same_items create_nodes([Xplain::Literal.new(value: 2)]), p3.children
    
    assert_same_items create_nodes([Xplain::Literal.new(value: 1)]), p4.children
    
  end



end