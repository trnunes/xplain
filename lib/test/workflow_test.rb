# require './test/xplain_unit_test'
# require './operations/filters/filter_factory'
# require './operations/refine'
# require './operations/filters/filter'
# require './operations/filters/simple_filter'
# require './operations/filters/composite_filter'
# require './operations/filters/and'
# require './operations/filters/or'
# require './operations/filters/equals'
# require './operations/filters/equals_one'
# require './operations/filters/contains'
# require './operations/filters/match'
# require './operations/filters/greater_than'
# require './operations/filters/greater_than_equal'
# require './operations/filters/less_than_equal'
# require './operations/filters/less_than'
# require './operations/filters/not'
# require './adapters/rdf/filter_interpreter'
# require './operations/pivot'
# require './operations/group'
# require './operations/pivot'
# require './operations/map'
# require './operations/intersect'
# require './operations/unite'
# require './operations/diff'
# 
# class WorkflowTest < XplainUnitTest
#   
  # def setup
    # super
    # Xplain.reset_workflow
  # end
  # def test_inexistent_operation
    # wf = Xplain.new_workflow
    # assert_raise NoMethodError do
      # op = wf.inexistent_operation(input: Xplain::Node.new(id: 'root'))
    # end
  # end
#   
  # def test_inexistent_auxiliary_function
    # wf = Xplain.new_workflow
    # assert_raise NoMethodError do
      # op = wf.refine(input: Xplain::Node.new(id: 'root')) do
        # equals do
          # relation "_:author"
          # entity "_:p2"
        # end
      # end.pivot(){inexistent_aux_function "_:author"}.execute()
    # end
  # end
#   
  # def test_chain_two_operations
    # wf = Xplain.new_workflow
    # op = wf.refine(input: Xplain::Node.new(id: 'root')) do
      # equals do
        # relation "_:author"
        # entity "_:p2"
      # end
    # end.pivot(){relation "_:author"}
#     
    # assert_false op.nil?
    # assert_equal Pivot, op.class
    # workflow = Xplain.get_current_workflow
    # pivot_node = workflow.nodes.first
    # refine_node = pivot_node.children[0]
    # assert_false pivot_node.nil?
  # end
# 
  # def test_chain_two_operations_executing_last_one
     # input_nodes = [
       # Xplain::Node.new(item: Xplain::Entity.new("_:paper1")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p2")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p3")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p4")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p5")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p6")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p8"))
     # ]
# 
     # root = Xplain::ResultSet.new(nodes:  input_nodes)
#      
     # expected_results = Set.new([Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p5")])
     # wf = Xplain.get_current_workflow
     # op = wf.pivot(input: root){relation "_:cite"}.refine do
         # equals do
           # relation "_:author"
           # entity "_:a1"
         # end
     # end
#      
      # rs = wf.execute
      # assert_false rs.first.children.empty?
      # assert_equal expected_results, Set.new(rs.first.children.map{|node| node.item})
#   
  # end
#   
  # def test_chain_intersect
    # wf = Xplain.new_workflow
    # ref = wf.refine(input: Xplain::Node.new(id: 'root')) do
      # equals do
        # relation "_:author"
        # entity "_:p2"
      # end
    # end
    # pivot = wf.pivot(input: Xplain::Node.new(id: 'root')){relation "_:author"}
    # op = pivot.intersect ref
    # workflow = Xplain.get_current_workflow
    # intersect_node = workflow.nodes.select{|node| node.item.is_a? Intersect}.first
    # assert_equal Set.new([pivot, ref]), Set.new(intersect_node.children.map{|n| n.item})
#     
  # end
#   
  # def test_chain_unite
    # wf = Xplain.new_workflow
    # ref = wf.refine(input: Xplain::Node.new(id: 'root')) do
      # equals do
        # relation "_:author"
        # entity "_:p2"
      # end
    # end
    # pivot = wf.pivot(input: Xplain::Node.new(id: 'root')){relation "_:author"}
    # op = pivot.unite ref
    # workflow = Xplain.get_current_workflow
    # intersect_node = workflow.nodes.select{|node| node.item.is_a? Unite}.first
    # assert_equal Set.new([pivot, ref]), Set.new(intersect_node.children.map{|n| n.item})
#     
  # end
#   
  # def test_chain_diff
    # wf = Xplain.new_workflow
    # ref = wf.refine(input: Xplain::Node.new(id: 'root')) do
      # equals do
        # relation "_:author"
        # entity "_:p2"
      # end
    # end
    # pivot = wf.pivot(input: Xplain::Node.new(id: 'root')){relation "_:author"}
    # op = pivot.diff ref
    # workflow = Xplain.get_current_workflow
    # intersect_node = workflow.nodes.select{|node| node.item.is_a? Diff}.first
    # assert_equal Set.new([pivot, ref]), Set.new(intersect_node.children.map{|n| n.item})
  # end
#   
  # def test_pivot_refine
    # input_nodes = [
      # Xplain::Node.new(item: Xplain::Entity.new("_:paper1")),
      # Xplain::Node.new(item: Xplain::Entity.new("_:p2")),
      # Xplain::Node.new(item: Xplain::Entity.new("_:p3")),
      # Xplain::Node.new(item: Xplain::Entity.new("_:p4")),
      # Xplain::Node.new(item: Xplain::Entity.new("_:p5")),
      # Xplain::Node.new(item: Xplain::Entity.new("_:p6")),
      # Xplain::Node.new(item: Xplain::Entity.new("_:p8"))
    # ]
# 
    # root = Xplain::ResultSet.new(nodes:  input_nodes)
#     
    # expected_results = Set.new([Xplain::Entity.new("_:p5")])
    # wf = Xplain.get_current_workflow
    # op = wf.pivot(input: root){relation "_:cite"}.refine do
      # And do [
        # equals do
          # relation "_:author"
          # entity "_:a1"
        # end,
        # equals do
          # relation "_:author"
          # entity "_:a2"
        # end
      # ]
      # end
    # end
    # assert_equal expected_results, Set.new(wf.execute.first.children.map{|n|n.item})
   # end
#    
   # def test_pivot_refine_intersect
     # input_nodes = [
       # Xplain::Node.new(item: Xplain::Entity.new("_:paper1")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p2")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p3")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p4")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p5")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p6")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p8"))
     # ]
# 
     # root = Xplain::ResultSet.new(nodes:  input_nodes)
#      
     # expected_results = Set.new([Xplain::Entity.new("_:p5")])
     # wf = Xplain.get_current_workflow
     # op = wf.pivot(input: root){relation "_:cite"}.refine do
         # equals do
           # relation "_:author"
           # entity "_:a1"
         # end
     # end.intersect( 
       # wf.pivot(input: root){relation "_:cite"}.refine do
         # equals do
           # relation "_:author"
           # entity "_:a2"
         # end
       # end
      # )
#     
      # rs = wf.execute
      # assert_false rs.first.children.empty?
      # assert_equal expected_results, Set.new(rs.first.children.map{|node| node.item})
#      
   # end
#    
   # def test_pivot_refine_unite
     # input_nodes = [
       # Xplain::Node.new(item: Xplain::Entity.new("_:paper1")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p2")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p3")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p4")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p5")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p6")),
       # Xplain::Node.new(item: Xplain::Entity.new("_:p8"))
     # ]
# 
     # root = Xplain::ResultSet.new(nodes:  input_nodes)
#      
     # expected_results = Set.new([Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5")])
     # wf = Xplain.get_current_workflow
     # op = wf.pivot(input: root){relation "_:cite"}.refine do
         # equals do
           # relation "_:author"
           # entity "_:a1"
         # end
     # end.unite( 
       # wf.pivot(input: root){relation "_:cite"}.refine do
         # equals do
           # relation "_:author"
           # entity "_:a2"
         # end
       # end
      # )
#     
      # rs = wf.execute
      # assert_false rs.first.children.empty?
      # assert_equal expected_results, Set.new(rs.first.children.map{|node| node.item})
#      
   # end
#    
   # def test_pivot_refine_diff
   # end
#   
# end