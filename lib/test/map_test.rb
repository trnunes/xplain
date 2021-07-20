require './test/xplain_unit_test'
Dir['./operations/xmap_aux/*.rb'].each{|f| require f}
Dir['./operations/aggregate_aux/*.rb'].each{|f| require f}
class MapTest < XplainUnitTest

  def test_map_by_empty_input_set
    root = Xplain::ResultSet.new(nodes:  [])

    rs = Xplain::Aggregate.new(inputs: root, mapping_relation: AggregateAux::Sum.new(Xplain::SchemaRelation.new(id: "_:cite"))).execute

    assert_true rs.children.empty?, rs.inspect
  end

  def test_sum_by_single_relation_0
    input_nodes = create_nodes [Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:p7")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    rs = Xplain::Aggregate.new(inputs: input, mapping_relation: AggregateAux::Sum.new(Xplain::SchemaRelation.new(id: "_:relevance"))).execute()
    
    assert_same_items_set rs.children, input_nodes
    assert_true rs.children.map{|n| n.children}.flatten.empty?
  end
  
  def test_sum_by_not_number
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p4")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    assert_raise NumericItemRequiredException do
      rs = Xplain::Aggregate.new(inputs: input, mapping_relation: AggregateAux::Sum.new(Xplain::SchemaRelation.new(id: "_:cite"))).execute()
    end
  end
  
  def test_sum_single_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    expr = Xplain::Aggregate.new(inputs: [input], mapping_relation: AggregateAux::Sum.new(Xplain::SchemaRelation.new(id: "_:relevance")))
    rs = @papers_session.execute(expr)
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.children.select{|node| node.item.id == "_:p3"}[0]
    p4 = rs.children.select{|node| node.item.id == "_:p4"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(30.0), Xplain::Literal.new(24.0), Xplain::Literal.new(20.0)]
    
    actual_rs_children = [p2.children[0], p3.children[0], p4.children[0]]
    
    assert_same_items_set expected_rs_children, actual_rs_children
  end
  
  def test_count_by_single_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    rs = Xplain::Aggregate.new(inputs: input, mapping_relation: AggregateAux::Count.new(Xplain::SchemaRelation.new(id: "_:cite"))).execute()
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p6 = rs.children.select{|node| node.item.id == "_:p6"}[0]
    paper1 = rs.children.select{|node| node.item.id == "_:paper1"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(0), Xplain::Literal.new(3), Xplain::Literal.new(3)]
    actual_rs_children = [p2.children[0], p6.children[0], paper1.children[0]]
    
    assert_same_items expected_rs_children, actual_rs_children
  end

  def test_count_by_inverse_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    rs = Xplain::Aggregate.new(inputs: input, mapping_relation: AggregateAux::Count.new(Xplain::SchemaRelation.new(id: "_:cite", inverse: true))).execute()
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    paper1 = rs.children.select{|node| node.item.id == "_:paper1"}[0]
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.children.select{|node| node.item.id == "_:p3"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(0), Xplain::Literal.new(2), Xplain::Literal.new(4)]
    actual_rs_children = [paper1.children[0], p2.children[0], p3.children[0]]
    
    assert_same_items expected_rs_children, actual_rs_children
  end
  
  def test_average
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    rs = Xplain::Aggregate.new(inputs: input, mapping_relation: AggregateAux::Avg.new(Xplain::SchemaRelation.new(id: "_:relevance"))).execute()
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.children.select{|node| node.item.id == "_:p3"}[0]
    p4 = rs.children.select{|node| node.item.id == "_:p4"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(15.0), Xplain::Literal.new(12.0), Xplain::Literal.new(10.0)]
    actual_rs_children = [p2.children[0], p3.children[0], p4.children[0]]

    assert_same_items expected_rs_children, actual_rs_children
  end
  
  def test_count_computed_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    computed_relation = input.get_level_relation(1)
    rs = Xplain::Aggregate.new(inputs: input, level: 2, mapping_relation: AggregateAux::Count.new()).execute()
    
    assert_equal 1, rs.children.size
    assert_same_items_set create_nodes([Xplain::Literal.new(3)]), rs.children
    
  end
  
  def test_count_computed_relation_level_2
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    input_nodes.first.children = create_nodes [Xplain::Entity.new("_:p2.1"), Xplain::Entity.new("_:p2.2"), Xplain::Entity.new("_:p2.3")]
    input_nodes[1].children = create_nodes [Xplain::Entity.new("_:p3.1"), Xplain::Entity.new("_:p3.2")]
    input_nodes[2].children = create_nodes [Xplain::Entity.new("_:p4.1")]
    
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    rs = Xplain::Aggregate.new(inputs: input, level: 3, mapping_relation: AggregateAux::Count.new()).execute()
    assert_equal 3, rs.children.size

    p2 = rs.children.select{|node| node.item.id == "_:p2"}.first
    p3 = rs.children.select{|node| node.item.id == "_:p3"}.first
    p4 = rs.children.select{|node| node.item.id == "_:p4"}.first
    
    assert_same_items create_nodes([Xplain::Literal.new(3)]), p2.children
    
    assert_same_items create_nodes([Xplain::Literal.new(2)]), p3.children
    
    assert_same_items create_nodes([Xplain::Literal.new(1)]), p4.children
    
  end


  def test_count_computed_relation_level_2_dsl
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    input_nodes.first.children = create_nodes [Xplain::Entity.new("_:p2.1"), Xplain::Entity.new("_:p2.2"), Xplain::Entity.new("_:p2.3")]
    input_nodes[1].children = create_nodes [Xplain::Entity.new("_:p3.1"), Xplain::Entity.new("_:p3.2")]
    input_nodes[2].children = create_nodes [Xplain::Entity.new("_:p4.1")]
    
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    rs = input.aggregate(level: 3){count}.execute()
    assert_equal 3, rs.children.size

    p2 = rs.children.select{|node| node.item.id == "_:p2"}.first
    p3 = rs.children.select{|node| node.item.id == "_:p3"}.first
    p4 = rs.children.select{|node| node.item.id == "_:p4"}.first
    
    assert_same_items create_nodes([Xplain::Literal.new(3)]), p2.children
    
    assert_same_items create_nodes([Xplain::Literal.new(2)]), p3.children
    
    assert_same_items create_nodes([Xplain::Literal.new(1)]), p4.children
    
  end
  
  def test_sum_single_relation_dsl
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    rs = input.aggregate do
      sum{relation "_:relevance"}      
    end.execute
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.children.select{|node| node.item.id == "_:p3"}[0]
    p4 = rs.children.select{|node| node.item.id == "_:p4"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(30.0), Xplain::Literal.new(24.0), Xplain::Literal.new(20.0)]
    actual_rs_children = [p2.children[0], p3.children[0], p4.children[0]]
    
    assert_same_items_set expected_rs_children, actual_rs_children
  end
  
  def test_count_by_single_relation_dsl
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    rs = input.aggregate do
      count{relation "_:cite"}      
    end.execute
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p6 = rs.children.select{|node| node.item.id == "_:p6"}[0]
    paper1 = rs.children.select{|node| node.item.id == "_:paper1"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(0), Xplain::Literal.new(3), Xplain::Literal.new(3)]
    actual_rs_children = [p2.children[0], p6.children[0], paper1.children[0]]
    
    assert_same_items expected_rs_children, actual_rs_children
  end

  def test_count_by_inverse_relation_dsl
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    rs = input.aggregate do
      count{relation inverse("_:cite")}      
    end.execute
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    paper1 = rs.children.select{|node| node.item.id == "_:paper1"}[0]
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.children.select{|node| node.item.id == "_:p3"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(0), Xplain::Literal.new(2), Xplain::Literal.new(4)]
    actual_rs_children = [paper1.children[0], p2.children[0], p3.children[0]]
    
    assert_same_items expected_rs_children, actual_rs_children
  end

  
  def test_average_dsl
    
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    input = Xplain::ResultSet.new(nodes:  input_nodes)
    
    
    rs = input.aggregate do
      avg{relation "_:relevance"}      
    end.execute
    
    assert_equal 3, rs.children.size
    assert_same_items_set input_nodes, rs.children
    
    p2 = rs.children.select{|node| node.item.id == "_:p2"}[0]
    p3 = rs.children.select{|node| node.item.id == "_:p3"}[0]
    p4 = rs.children.select{|node| node.item.id == "_:p4"}[0]
    
    expected_rs_children = create_nodes [Xplain::Literal.new(15.0), Xplain::Literal.new(12.0), Xplain::Literal.new(10.0)]
    actual_rs_children = [p2.children[0], p3.children[0], p4.children[0]]
    
    assert_same_items expected_rs_children, actual_rs_children
  end

end