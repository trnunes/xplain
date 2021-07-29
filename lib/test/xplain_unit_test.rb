require 'forwardable'
require "test/unit"
require 'linkeddata'
require 'pry'
require './adapters/memory/memory_repository'
require './mixins/config'
require './mixins/operation_factory'
require './mixins/writable.rb'
require './mixins/readable.rb'
require './mixins/dsl_callable.rb'
require './execution/workflow.rb'

require './mixins/enumerable'
require './mixins/relation'
require './exceptions/missing_relation_exception'
require './exceptions/missing_argument_exception'
require './exceptions/missing_value_exception'
require './exceptions/invalid_input_exception'
require './exceptions/disconnected_operation_exception'
require './exceptions/missing_auxiliary_function_exception'
require './exceptions/numeric_item_required_exception'

require './mixins/graph_converter'
require './model/node'
require './model/edge'
require './model/item_factory'
require './model/item'
require './model/entity'
require './model/type'
require './model/session'
require './model/literal'
require './model/schema_relation'
require './model/path_relation'
require './model/namespace'
require './model/result_set'
require './model/remote_set'
require './model/relation_handler'
require './model/sequence'

require './repositories/data_server'
require './repositories/schema_relation_gateway'
require './repositories/path_relation_gateway'

require './mixins/model_factory'

(Dir["./adapters/*/lib/*.rb"] - Dir["./adapters/*/lib/*data_server.rb"]).each {|file| require file }
Dir["./adapters/*/lib/data_server.rb"].each {|file| require file }

require './visualization/visualization'
require 'securerandom'
require './operations/auxiliary_function'
require './operations/operation'
require './operations/set_operation'
require './operations/group_aux/grouping_relation'
require './operations/load'
require './operations/refine_aux/filter_factory'
require './operations/refine_aux/generic_filter'
require './operations/refine_aux/relation_filter'
require './operations/refine_aux/composite_filter'
require './operations/refine_aux/in_memory_filter_interpreter'

require './execution/dsl_parser.rb'

#TODO Duplicated code with xplain.rb!
module Xplain
  @@base_dir = ""
  @@cache_results = false
  @@persist_extensions = true
  @@memory_cache = MemoryRepository.new
  
  class << self
    def base_dir=(base_dir_path)
      @@base_dir = base_dir_path
    end
    def persist_extensions=(bool)
      @@persist_extensions = bool
    end
    def persist_extensions?
      @@persist_extensions
    end
  
    def base_dir
      @@base_dir
    end
    
    def cache_results?
      @@cache_results
    end
    
    def cache_results=(bool)
      @@cache_results = bool
    end
    
    def memory_cache
      @@memory_cache
    end
    
    def clear_cache
      @@memory_cache = MemoryRepository.new
    end
    
    def const_missing(name)
      
  
      instance = nil
      
      begin
        require Xplain.base_dir + "operations/" + name.to_s.to_underscore + ".rb"
        
      rescue Exception => e
        
        puts e.to_s
      end
      
      klass = Object.const_get "Xplain::" + name.to_s.to_camel_case
  
      if !Xplain::Operation.operation_class? klass
        raise NoMethodError.new("Operation #{klass.to_s} not supported!")           
      end
          
      return klass
    end
  end
end

class InputProxy
  attr_accessor :input_nodes
  def initialize(input_nodes = [])
    @input_nodes = input_nodes
  end
  
  def get_level(level)
    if(level == 1)
      root = Xplain::Node.new("rootProxy")
      root.children = @input_nodes
      return [root]
    elsif(level == 2)
      return @input_nodes
    elsif(level == 3)
      return @input_nodes.map{|n|n.children}.flatten
    end
  end
  
  def count_levels
    nodes = @input_nodes || []
    count = 1
    while !nodes.empty?
      count += 1
      nodes = nodes.map{|node| node.children}.flatten
    end
    return count
  end
  
  def empty?
    @input_nodes.empty?
  end
  
  def copy
    InputProxy.new(@input_nodes.dup)
  end
  
  def leaves()
    @input_nodes
  end
end

class XplainUnitTest < Test::Unit::TestCase
  def setup
    Xplain.base_dir = "./"
    Xplain::SetSequence.reset
    load_papers_server
    load_simple_server
    @papers_session = Xplain::Session.new id: "sid"
    @papers_session.server = @papers_server
    profile = Xplain::Visualization::Profile.new(id: "test")
    @papers_session.view_profile = profile
    Xplain::clear_cache
  end

  def load_papers_server
    papers_graph = RDF::Graph.new do |graph|
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p2")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:cite"), RDF::URI("_:p4")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("http://xplain/cites"), RDF::URI("_:p2")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("http://xplain/cites"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("http://xplain/cites"), RDF::URI("_:p4")]      
      graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p2")]
      graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:p6"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p7"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:p7"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p8"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p8"),  RDF::URI("_:cite"), RDF::URI("_:p3")]
      graph << [RDF::URI("_:p9"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      graph << [RDF::URI("_:p10"),  RDF::URI("_:cite"), RDF::URI("_:p5")]
      
      graph << [RDF::URI("_:p9"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDF::URI("_:type1")]
      graph << [RDF::URI("_:p10"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDF::URI("_:type2")]

      graph << [RDF::URI("_:paper1"),  RDF::URI("_:submittedTo"), RDF::URI("_:journal1")]
      
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:author"),RDF::URI("_:a1") ]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:author"),RDF::URI("_:a2") ]
      graph << [RDF::URI("_:p2"),  RDF::URI("_:author"), RDF::URI("_:a1")]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:author"), RDF::URI("_:a2")]
      graph << [RDF::URI("_:p5"),  RDF::URI("_:author"), RDF::URI("_:a1")]
      graph << [RDF::URI("_:p5"),  RDF::URI("_:author"), RDF::URI("_:a2")]
      graph << [RDF::URI("_:p6"),  RDF::URI("_:author"), RDF::URI("_:a2")]
      graph << [RDF::URI("_:p20"),  RDF::URI("_:author"), RDF::URI("_:a3")]

      graph << [RDF::URI("_:p2"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal1")]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal2")]
      graph << [RDF::URI("_:p4"),  RDF::URI("_:publishedOn"), RDF::URI("_:journal1")]
      
      graph << [RDF::URI("_:journal1"),  RDF::URI("_:releaseYear"), RDF::Literal.new("2005", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:journal2"),  RDF::URI("_:releaseYear"), RDF::Literal.new("2010", datatype: RDF::XSD.string)]
      
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k1")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k2")]
      graph << [RDF::URI("_:paper1"),  RDF::URI("_:keywords"), RDF::URI("_:k3")]
      
      graph << [RDF::URI("_:p2"),  RDF::URI("_:keywords"), RDF::URI("_:k3")]      
      graph << [RDF::URI("_:p3"),  RDF::URI("_:keywords"), RDF::URI("_:k2")]
      graph << [RDF::URI("_:p5"),  RDF::URI("_:keywords"), RDF::URI("_:k1")]
      
      graph << [RDF::URI("_:p2"),  RDF::URI("_:publicationYear"), RDF::Literal.new("2000", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:publicationYear"), RDF::Literal.new("1998", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:p4"),  RDF::URI("_:publicationYear"), RDF::Literal.new("2010", datatype: RDF::XSD.string)]     
      
      graph << [RDF::URI("_:p2"),  RDF::URI("_:relevance"), RDF::Literal.new(10, datatype: RDF::XSD.int)]
      graph << [RDF::URI("_:p2"),  RDF::URI("_:relevance"), RDF::Literal.new(20, datatype: RDF::XSD.int)]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:relevance"), RDF::Literal.new(8, datatype: RDF::XSD.int)]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:relevance"), RDF::Literal.new(16, datatype: RDF::XSD.int)]
      graph << [RDF::URI("_:p4"),  RDF::URI("_:relevance"), RDF::Literal.new(5, datatype: RDF::XSD.int)]
      graph << [RDF::URI("_:p4"),  RDF::URI("_:relevance"), RDF::Literal.new(15, datatype: RDF::XSD.int)]
    
      graph << [RDF::URI("_:paper1"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("paper1_keyword", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:paper1"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("common_keyword", datatype: RDF::XSD.string)]
            
      graph << [RDF::URI("_:p2"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("paper2_keyword1 middle paper2_keyword2", datatype: RDF::XSD.string)]
      
      graph << [RDF::URI("_:p2"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("common_keyword", datatype: RDF::XSD.string)]      
      
      graph << [RDF::URI("_:p3"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("paper3_keyword", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:p3"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("common_keyword", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:alternative_label_property"), RDF::Literal.new("common_keyword middle paper3_keyword2 end", datatype: RDF::XSD.string)]
      
      graph << [RDF::URI("_:p4"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("paper4_keyword", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:p4"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("common_keyword", datatype: RDF::XSD.string)]
      
      graph << [RDF::URI("_:p5"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("paper5_keyword", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:p5"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("common_keyword", datatype: RDF::XSD.string)]
      
      graph << [RDF::URI("_:p6"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("paper6_keyword", datatype: RDF::XSD.string)]
      graph << [RDF::URI("_:p6"),  RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#label"), RDF::Literal.new("common_keyword", datatype: RDF::XSD.string)]
           
           
      
    end

    @papers_server = Xplain::RDF::DataServer.new graph: papers_graph
    Xplain.set_default_server class: Xplain::RDF::DataServer, graph: papers_graph
  end
  
  def load_simple_server
    @graph = RDF::Graph.new do |graph|
      graph << [RDF::URI("_:p1"),  RDF::URI("_:r1"), RDF::URI("_:o1")]
      graph << [RDF::URI("_:p1"),  RDF::URI("_:r1"), RDF::URI("_:o2")]
      graph << [RDF::URI("_:p1"),  RDF::URI("_:r2"), RDF::URI("_:o2")]
      graph << [RDF::URI("_:p2"),  RDF::URI("_:r1"), RDF::URI("_:o2")]
      graph << [RDF::URI("_:p3"),  RDF::URI("_:r1"), RDF::URI("_:o2")]
      graph << [RDF::URI("_:p2"),  RDF::URI("_:r2"), RDF::URI("_:o2")]
      
      graph << [RDF::URI("_:p1"),  RDF::RDFS.label, RDF::Literal('lp1')]
      graph << [RDF::URI("_:p2"),  RDF::RDFS.label, RDF::Literal('lp2')]
      graph << [RDF::URI("_:r1"),  RDF::RDFS.label, RDF::Literal('lr1')]
      graph << [RDF::URI("_:r2"),  RDF::RDFS.label, RDF::Literal('lr2')]
      graph << [RDF::URI("_:o1"),  RDF::RDFS.label, RDF::Literal('lo1')]
      graph << [RDF::URI("_:o2"),  RDF::RDFS.label, RDF::Literal('lo2')]
    end

    @server = Xplain::RDF::DataServer.new graph: @graph, lookup_service: "Xplain::DbpediaLookup"
  end
  
  def create_nodes(items)
    items.map{|item| Xplain::Node.new(item: item)}
  end
  
  def assert_same_items(node_list1, node_list2)
    
    assert_equal node_list1.class, node_list2.class
    
    items_list1 = node_list1.to_a.compact.map{|node| node.item if node.is_a? Xplain::Node}
    items_list2 = node_list2.to_a.compact.map{|node| node.item if node.is_a? Xplain::Node}
    
    nodes_list_class = node_list1.class
    assert_equal nodes_list_class.new(items_list1), nodes_list_class.new(items_list2)    
  end
  
  def assert_same_items_set(node_list1, node_list2)
    assert_same_items(Set.new(node_list1), Set.new(node_list2))
  end
  
  def assert_same_items_tree_set(root1, root2, debug=false)
    item1 = root1.item if root1.is_a? Xplain::Node
    item2 = root2.item if root2.is_a? Xplain::Node
    
    assert_equal item1, item2
    
    assert_same_items_set root1.children, root2.children
    
    root1_parent_edges = root1.parent_edges.map{|edge| [edge.origin.item, edge.target.item]}
    root2_parent_edges = root2.parent_edges.map{|edge| [edge.origin.item, edge.target.item]}
    
    assert_equal root1_parent_edges, root2_parent_edges, "node #{root1.item.to_s} and node #{root2.item.to_s} parent edges are not the same."
    for child_root1 in root1.children
       child_root2 = root2.children.select{|node| node.item == child_root1.item}.first
       assert_same_items_tree_set(child_root1, child_root2)
    end
  end
  
  def assert_same_items_tree_set_no_root(root1, root2, debug=false)
    root2.children.each{|child| child.parent_edges.each{|parent_edge| parent_edge.origin = root1 if parent_edge.origin == root2} }
    
    assert_equal root1.children.size, root2.children.size, "Children sets do no have the same size: #{root1.children.size} <> #{root2.children.size}"
    for child_root1 in root1.children
       child_root2 = root2.children.select{|node| node.item == child_root1.item}.first
       
       assert_same_items_tree_set(child_root1, child_root2, debug)
       
    end
  end
  
  def assert_same_result_set_no_title(rs1, rs2)
    rs1.title = rs2.title
    assert_same_result_set rs1, rs2
    
  end
  
  def assert_same_result_set(rs1, rs2, debug=false)
    assert_true rs1.is_a? Xplain::ResultSet
    assert_true rs2.is_a? Xplain::ResultSet
    assert_equal rs1.title, rs2.title, "Titles are not the same!"
    assert_equal rs1.annotations, rs2.annotations, "Annotations are not the same!"
    assert_same_items_tree_set_no_root rs1, rs2, debug
  end
    

  def test_assert_same_items_1_level
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    input1 = Xplain::ResultSet.new(id: "_:rs", nodes:  [i1p1, i1p2])

    i2p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i2p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i2p3 = Xplain::Node.new(item: Xplain::Entity.new("_:p3"))    
    input2 = Xplain::ResultSet.new(id: "_:rs", nodes:  [i2p1, i2p2, i2p3])

    i3p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i3p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    input3 = Xplain::ResultSet.new(id: "_:rs2", nodes:  [i3p1, i3p2])
    
    
    assert_nothing_raised(Test::Unit::AssertionFailedError) {  assert_same_result_set_no_title(input1, input3)}
    assert_nothing_raised(Test::Unit::AssertionFailedError) {  assert_same_result_set_no_title(input2, input2)}
    assert_raise(Test::Unit::AssertionFailedError) {assert_same_result_set_no_title(input2, input1)}
    assert_raise(Test::Unit::AssertionFailedError) {assert_same_result_set_no_title(input2, input3)}
  end

  def test_assert_same_items_2_levels
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i1p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"))]
    i1p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2.2"))]
    input1 = Xplain::ResultSet.new(nodes:  [i1p1, i1p2])

    i2p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i2p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i2p3 = Xplain::Node.new(item: Xplain::Entity.new("_:p3"))
    i2p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p1.3"))]
    i2p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2.3"))]
    i2p3.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p3.1"))]
    input2 = Xplain::ResultSet.new(nodes:  [i2p1, i2p2, i2p3])

    i3p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i3p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i3p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p1.2"))]
    i3p2.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p2.1")), Xplain::Node.new(item: Xplain::Entity.new("_:p2.2"))]
    input3 = Xplain::ResultSet.new(nodes:  [i3p1, i3p2])
    
    
    assert_nothing_raised(Test::Unit::AssertionFailedError) {  assert_same_result_set_no_title(input1, input3)}
    assert_nothing_raised(Test::Unit::AssertionFailedError) {  assert_same_result_set_no_title(input2, input2)}
    assert_raise(Test::Unit::AssertionFailedError) {assert_same_result_set_no_title(input2, input1)}
    assert_raise(Test::Unit::AssertionFailedError) {assert_same_result_set_no_title(input2, input3)}
  end
  
  def test_assert_same_items_different_levels
    i1p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i1p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i1p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"))]    
    input1 = Xplain::ResultSet.new(nodes:  [i1p1, i1p2])

    i2p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i2p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    input2 = Xplain::ResultSet.new(nodes:  [i2p1, i2p2])

    i3p1 = Xplain::Node.new(item: Xplain::Entity.new("_:p1"))
    i3p2 = Xplain::Node.new(item: Xplain::Entity.new("_:p2"))
    i3p1.children = [Xplain::Node.new(item: Xplain::Entity.new("_:p1.1"))]
    input3 = Xplain::ResultSet.new(nodes:  [i3p1, i3p2])
    
    
    assert_nothing_raised(Test::Unit::AssertionFailedError) {  assert_same_result_set_no_title(input1, input3)}
    assert_nothing_raised(Test::Unit::AssertionFailedError) {  assert_same_result_set_no_title(input2, input2)}
    assert_raise(Test::Unit::AssertionFailedError) {assert_same_result_set_no_title(input2, input1)}
    assert_raise(Test::Unit::AssertionFailedError) {assert_same_result_set_no_title(input2, input3)}
  end

end
