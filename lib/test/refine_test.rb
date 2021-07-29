
require './test/xplain_unit_test'
require './operations/refine_aux/filter_factory'
require './operations/refine_aux/generic_filter'
require './operations/refine_aux/relation_filter'
require './operations/refine_aux/composite_filter'

require './operations/refine_aux/in_memory_filter_interpreter'

class Xplain::RefineTest < XplainUnitTest
  
  def test_filter_empty_input
    input_nodes = []
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    actual_results = Xplain::Refine.new(inputs: root) do
      equals do
        relation "_:cite"
        entity "_:p2"
      end
    end.execute()
    assert_true actual_results.children.empty?, actual_results.children.inspect
  end
  
  def test_filter_nil_relation
    input_nodes = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4"), Xplain::Entity.new(server: @papers_server, id: "_:p5")]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    begin
      actual_results = Xplain::Refine.new(inputs: root) do
        equals do
          entity "_:p2"
        end
      end.execute()
    rescue MissingRelationException => e
      assert true
      return
    end
    assert false
  end

  def test_filter_empty_relation
    input_nodes = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4"), Xplain::Entity.new(server: @papers_server, id: "_:p5")]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    begin
      actual_results = Xplain::Refine.new(inputs: root) do
        equals do
          relation nil
          entity "_:p2"
        end
      end.execute()
    rescue MissingRelationException => e
      assert true
      return
    end
    assert false
  end
  
  def test_filter_absent_value
    input_nodes = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4"), Xplain::Entity.new(server: @papers_server, id: "_:p5")]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    begin
      actual_results = Xplain::Refine.new(inputs: root) do
        equals do
          relation "_:cite"
        end
      end.execute()
    rescue MissingValueException => e
      assert true
      return
    end
    assert false
  end

  def test_filter_empty_value
    input_nodes = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4"), Xplain::Entity.new(server: @papers_server, id: "_:p5")]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    begin
      actual_results = Xplain::Refine.new(inputs: root) do
        equals do
          relation "_:cite"
          entity nil
        end
      end.execute()
    rescue MissingValueException => e
      assert true
      return
    end
    assert false
    
  end
  
  def test_and_less_than_2
    input_nodes = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4"), Xplain::Entity.new(server: @papers_server, id: "_:p5")]
    
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    actual_results = Xplain::Refine.new(inputs: root) do
      And do[
        equals do
          relation "_:cite"
          entity "_:p2"
        end
      ]
      end
    end.execute()
    assert_equal [Xplain::Entity.new(server: @papers_server, id: "_:paper1")], actual_results.children.map{|n|n.item}
    
  end
  
  def test_or_less_than_2
    input_nodes = create_nodes [Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4"), Xplain::Entity.new(server: @papers_server, id: "_:p5")]
    
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    actual_results = Xplain::Refine.new(inputs: root) do
      Or do[
        equals do
          relation "_:cite"
          entity "_:p2"
        end
      ]
      end
    end.execute()
    assert_equal [Xplain::Entity.new(server: @papers_server, id: "_:paper1")], actual_results.children.map{|n|n.item}
    
  end
  
  def test_refine_equal
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p5"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:paper1")])

    actual_results = Xplain::Refine.new(inputs: root) do
      equals do
        relation "_:cite"
        entity "_:p2"
      end
    end.execute()
    
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end

  
  def test_refine_equal_literal
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2")),
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:journal1")])

    actual_results = Xplain::Refine.new(inputs: root) do
      equals do
        relation "_:releaseYear"
        literal "2005"
      end
    end.execute()
    
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end


  def test_refine_equal_literal_OR_same_relation
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2")),
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:journal1"), Xplain::Entity.new(server: @papers_server, id: "_:journal2")])

    actual_results = Xplain::Refine.new(inputs: root) do
      Or do [
        equals do
          relation "_:releaseYear"
          literal "2005"
        end,
        equals do
          relation "_:releaseYear"
          literal "2010"
        end
      ]
      end
    end.execute()
    
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end

  def test_filter_equal_literal_OR_different_relation
    input_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p2"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p5"), Xplain::Entity.new(server: @papers_server, id: "_:p6"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p7"), Xplain::Entity.new(server: @papers_server, id: "_:p8"),
      Xplain::Entity.new(server: @papers_server, id: "_:p9"), Xplain::Entity.new(server: @papers_server, id: "_:p10")
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_output_nodes = create_nodes [
      Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p6"), 
      Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p5")
    ]
    actual_results = Xplain::Refine.new(inputs: root) do
      Or do [
        equals do
          relation "_:cite"
          entity "_:p2"
        end,
        equals do
          relation "_:author"
          entity "_:a1"
        end
      ]
      end
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal Set.new(expected_output_nodes.map{|n| n.item}), Set.new(actual_results.children.map{|n|n.item})
  end
  

  def test_refine_equal_literal_AND_same_relation
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p5")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p5")])
    actual_results = Xplain::Refine.new(inputs: root) do
      And do
        [
          equals do
            relation "_:author"
            entity "_:a1"
          end,
          equals do
            relation "_:author"
            entity "_:a2"
          end
        ]
      end
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end
  
  def test_refine_property_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p5")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p8"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:paper1"), Xplain::Entity.new(server: @papers_server, id: "_:p6"), Xplain::Entity.new(server: @papers_server, id: "_:p8")])
    actual_results = Xplain::Refine.new(inputs: root) do
      And do [
        equals do
          relation "_:cite", "_:author"
          entity "_:a1"
        end,
        equals do
          relation "_:cite", "_:author"
          entity "_:a2"
        end
      ]
      end
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end
  
  def test_refine_property_path_size3
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p5")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p8"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:p2"), Xplain::Entity.new(server: @papers_server, id: "_:p3"), Xplain::Entity.new(server: @papers_server, id: "_:p4")])
    actual_results = Xplain::Refine.new(inputs: root) do
      equals do
        relation inverse("_:cite"), "_:submittedTo", "_:releaseYear"
        literal "2005"
      end
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end

  def test_refine_inverse_property_path
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a4")),
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:a1"), Xplain::Entity.new(server: @papers_server, id: "_:a2")])
    actual_results = Xplain::Refine.new(inputs: root) do 
      equals do
        relation inverse("_:author"), inverse("_:cite")
        entity "_:p10"
      end
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end  
  
  def test_refine_custom_filter_select
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a4")),
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:a1")])
    actual_results = Xplain::Refine.new(inputs: root) do
      c_filter "|e| e.item.id == \"_:a1\""
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end
  
  def test_refine_named_cfilter_select
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a4")),
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:a1")])
    actual_results = Xplain::Refine.new(inputs: root) do
      c_filter name: :by_id, code: "|e| e.item.id == \"_:a1\""
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end

  def test_refine_named_cfilter_select_AND
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:a4")),
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:a1")])
    actual_results = Xplain::Refine.new(inputs: root) do 
      And do 
        [
          c_filter(name: :by_id, code: '|e| e.item.text.include? "a1"')
        ]
      end
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})
  end

  def test_refine_named_cfilter_select_AND_dataset_filter
    input_nodes = [
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p5")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p6")),
      Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p8"))
    ]
    root = Xplain::ResultSet.new(nodes:  input_nodes)
    
    expected_results = Set.new([Xplain::Entity.new(server: @papers_server, id: "_:p6"), Xplain::Entity.new(server: @papers_server, id: "_:p8")])
    actual_results = Xplain::Refine.new(inputs: root) do
      And do [
        equals do
          relation "_:cite", "_:author"
          entity "_:a1"
        end,
        c_filter(name: :by_id, code: '|e| e.item.text.include?("p6") || e.item.text.include?("p8")')
      ]
      end
    end.execute()
    assert_false actual_results.children.empty?
    assert_equal expected_results, Set.new(actual_results.children.map{|node| node.item})

  end
  
  def test_refine_level_2_set

    paper1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1"))
    p2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    p3 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    p4 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4"))
    
    journal1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1"))
    journal2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2"))
    
    journal1.children = [paper1, p2]
    journal2.children = [p3, p4]
    
    input = Xplain::ResultSet.new(nodes:  [journal1, journal2])
    
    expected_journal1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1"))
    expected_journal1.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")), Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))]
    expected_results1 = Xplain::ResultSet.new(nodes:  [expected_journal1])
    
    expected_journal2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2"))
    expected_journal2.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3")), Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4"))]    
    expected_results2 = Xplain::ResultSet.new(nodes:  [expected_journal2])
    
    actual_results = Xplain::Refine.new(inputs: input, level: 2) do
      equals do
        relation "_:releaseYear"
        literal "2005"
      end
    end.execute()
    actual_results.title = expected_results1.title
    assert_same_result_set_no_title actual_results, expected_results1

    actual_results = Xplain::Refine.new(inputs: input, level: 2) do
      equals do
        relation "_:releaseYear"
        literal "2010"
      end
    end.execute()
    actual_results.title = expected_results2.title
    assert_same_result_set_no_title actual_results, expected_results2
  end


  def test_refine_level_3_set

    paper1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1"))
    p2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    p3 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    p4 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4"))
    
    journal1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1"))
    journal2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2"))
    
    journal1.children = [paper1, p2]
    journal2.children = [p3, p4]

    input = Xplain::ResultSet.new(id: "test_set", nodes: [journal1, journal2])
    
    expected_journal1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1"))
    expected_journal1.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1")), Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))]
    
    expected_journal2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2"))
    expected_journal2.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))]
    
    expected_results1 = Xplain::ResultSet.new(id: "test_set", nodes: [expected_journal1])
    expected_results2 = Xplain::ResultSet.new(id: "test_set", nodes: [expected_journal2])
    
    actual_results = Xplain::Refine.new(inputs: input, level: 3) do
      equals do
        relation "_:author"
        entity "_:a1"
      end
    end.execute()
    assert_same_result_set_no_title expected_results1, actual_results

    actual_results = Xplain::Refine.new(inputs: input, level: 3) do
      equals do
        relation "_:publishedOn"
        entity "_:journal2"
      end
    end.execute()

    assert_same_result_set_no_title expected_results2, actual_results
  end
  
  def test_refine_level_3_set_repeated_children

    paper1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:paper1"))
    p2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p2"))
    p3 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    p4 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p4"))
    
    journal1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1"))
    journal2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2"))
    
    p3_j1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))
    journal1.children = [paper1, p2, p3_j1]
    journal2.children = [p3, p4]

    input = Xplain::ResultSet.new(id: "test_set", nodes: [journal1, journal2])
    
    expected_journal1 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal1"))
    expected_journal1.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))]
    
    expected_journal2 = Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:journal2"))
    expected_journal2.children = [Xplain::Node.new(item: Xplain::Entity.new(server: @papers_server, id: "_:p3"))]
    
    
    expected_results = Xplain::ResultSet.new(id: "test_set", nodes: [expected_journal2, expected_journal1])

    actual_results = Xplain::Refine.new(inputs: input, level: 3) do
      equals do
        relation "_:publishedOn"
        entity "_:journal2"
      end
    end.execute() 
    assert_same_result_set_no_title actual_results, expected_results
  end
end