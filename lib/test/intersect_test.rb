require './test/xplain_unit_test'

class Xplain::IntersectTest < XplainUnitTest

  def test_empty_input_set
    input_nodes = []
    
    actual_results = Xplain::Intersect.new.get_results(input: [input_nodes, input_nodes])
    assert_true actual_results.empty?
  end

  def test_single_input
    input_nodes = create_nodes [
      Xplain::Entity.new("_:p1"), 
      Xplain::Entity.new("_:p2")
    ]
    
    actual_results = Xplain::Intersect.new.get_results(input: [input_nodes])
    assert_same_items_set input_nodes, actual_results
  end
  
  def test_nil_input
    
    actual_results = Xplain::Intersect.new.get_results(input: nil)
    
  end
    
  def test_intersect_1_height
    input1_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p1")),
      Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    ]
    input_1 = input1_nodes


    input2_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new("_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new("_:p3"))
    ]
    input_2 = input2_nodes
    
    
    expected_results = create_nodes [Xplain::Entity.new("_:p2")]

    actual_results = Xplain::Intersect.new.get_results(input: [input_1, input_2])
    assert_false actual_results.empty?
    assert_same_items_set actual_results, expected_results
    
  end

  def test_intersect_2_height
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i1p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"))]
    i1p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2.2"))]
    input1 = [i1p1, i1p2]
    
    i2p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i2p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i2p3 = Xplain::Node.new(item: Xplain::Entity.new("_:p3"))
    i2p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p1.3"))]
    i2p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2.3"))]
    i2p3.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p3.1"))]
    input2 = [i2p1, i2p2, i2p3]
    
    expected_p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    expected_p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    expected_p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"))]
    expected_p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1"))]
    
    expected_output = [expected_p1, expected_p2]

    actual_results = Xplain::Intersect.new.get_results(input: [input1, input2])
    assert_false actual_results.empty?
    assert_same_items_set actual_results, expected_output 
    
  end
  

    
end